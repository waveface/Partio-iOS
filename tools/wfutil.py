#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import logging
import time
import random
import urllib
import urllib2
import mimetools
import mimetypes
import gzip
import json
import itertools
import argparse
import uuid
import types
from cStringIO import StringIO

class V2API:
    AUTH_SIGNUP='/auth/signup'
    AUTH_LOGIN='/auth/login'
    AUTH_LOGOUT='/auth/logout'
    
    STATIONS_SIGNUP='/stations/signup'
    STATIONS_LOGON='/stations/logOn'
    STATIONS_LOGOFF='/stations/logOff'
    STATIONS_OFFLINE='/stations/offline'
    STATIONS_SIGNOFF='/stations/signoff'
    STATIONS_HEARTBEAT='/stations/heartbeat'
    
    POSTS_GET_SINGLE='/posts/getSingle'
    POSTS_GET='/posts/get'
    POSTS_GET_LATEST='/posts/getLatest'
    POSTS_NEW='/posts/new'
    POSTS_NEW_COMMENT='/posts/newComment'
    POSTS_FETCH_BY_FILTER='/posts/fetchByFilter'
    
    USERS_GET='/users/get'
    USERS_UPDATE='/users/update'
    USERS_PASSWD='/users/passwd'
    USERS_FIND_MY_STATION='/users/findMyStation'
    
    GROUPS_CREATE='/groups/create'
    GROUPS_GET='/groups/get'
    GROUPS_UPDATE='/groups/update'
    GROUPS_DELETE='/groups/delete'
    GROUPS_INVITE_USER='/groups/inviteUser'
    GROUPS_KICK_USER='/groups/kickUser'
    
    ATTACHMENTS_UPLOAD='/attachments/upload'
    ATTACHMENTS_VIEW='/attachments/view'
    
    PREVIEWS_GET='/previews/get'
    
    FOOTPRINTS_GET_LAST_SCAN='/footprints/getLastScan'
    FOOTPRINTS_SET_LAST_SCAN='/footprints/setLastScan'
    FOOTPRINTS_GET_LAST_READ='/footprints/getLastRead'
    FOOTPRINTS_SET_LAST_READ='/footprints/setLastRead'
    
    WEBCLIENT_GET_RESET_EMAIL_TOKEN='/webclient/getResetEmailToken'
    WEBCLIENT_GET_RESET_PASSWORD_TOKEN='/webclient/getResetPasswordToken'
    WEBCLIENT_RESET_EMAIL='/webclient/resetEmail'
    WEBCLIENT_RESET_PASSWORD='/webclient/resetPassword'

class HttpRedirectHandler(urllib2.HTTPRedirectHandler):
    def http_error_302(self, req, fp, code, msg, headers):
        raise urllib2.HTTPError(req.get_full_url(), code, msg, headers, fp)

class MultiPartForm(dict):
    """Accumulate the data to be used when posting a form."""

    def __init__(self):
        self.files = []
        self.boundary = mimetools.choose_boundary()
        return
    
    def get_content_type(self):
        return 'multipart/form-data; boundary=%s' % self.boundary

    def add_file(self, filename, fileHandle, mimetype=None):
        body = fileHandle.read()
        if mimetype is None:
            mimetype = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
        self.files.append((filename, mimetype, body))
        return
    
    def __str__(self):
        """Return a string representing the form data, including attached files."""
        parts = []
        part_boundary = '--' + self.boundary
        
        # Add the form fields
        parts.extend([part_boundary,'Content-Disposition: form-data; name="%s"' % name,'', value,] for name, value in self.items())
        
        # Add the files to upload
        parts.extend([part_boundary,'Content-Disposition: form-data; name=file; filename="%s"' % (filename),'Content-Type: %s' % content_type,'',body,]
            for filename, content_type, body in self.files)
        flattened = list(itertools.chain(*parts))
        flattened.append('--' + self.boundary + '--')
        flattened.append('')
        buf=StringIO()
        for s in flattened[:-1]:
            buf.write(s)
            buf.write('\r\n')
        buf.write(flattened[-1])
        return buf.getvalue()

def convertToUtf8(s):
    if type(s) not in (type(u''), type('')):
        return s
    if type(s)==type(u''):
        return s.encode('utf8')
    return unicode(s, 'utf8').encode('utf8')

class WfClient(object):
    apiKey='74ab96e4-06b3-5307-bf05-21ed5b0a2e11' # Automation API keys
    user=None
    password=None
    def __init__(self, server, station=None, defaultTimeout=30, useCookie=0):
        self.server=server
        self.station= station
        self.defaultTimeout=defaultTimeout
        self.sessionToken=None
        self.apiRetCode=None
        if useCookie:
            self.opener=urllib2.build_opener(urllib2.HTTPCookieProcessor(),HttpRedirectHandler())
        else:
            self.opener=urllib2.build_opener(HttpRedirectHandler())
                
    def _composeUrl(self,path,dicData):
        if path.startswith('http'):
            return path
        base=self.server
        if self.station:
            if path.startswith('/attachments'):
                logging.info('upload attachment to %s',self.station)
                base=self.station
            elif path.startswith(V2API.POSTS_NEW) and 'attachment_id_array' in dicData:
                base=self.station
        return base+'/v2'+path
    
    def httpGet(self,apiPath,dicData):
        dic=self._httpReq('GET', apiPath, dicData)
        return dic
    
    def httpPost(self,apiPath,dicData):
        dic=self._httpReq('POST', apiPath, dicData)
        return dic

    def multiPartPost(self,apiPath,dicData,lstFile=()):
        form = MultiPartForm()
        form.update(dicData)
        for filename,fileHandle,mimetype in lstFile:
            form.add_file(filename, fileHandle, mimetype)
        dicHeaders={'Content-type':form.get_content_type()}
        return self._httpReq('POST',apiPath, form, dicHeaders)
    
    def open(self, method, apiPath, dicData):
        return self._httpReq(method.upper(),apiPath, dicData)
        
    def _httpReq(self,method,apiPath,data,dicHeaders={}):
        if type(data)==type({}):
            data=data.copy()
        url=self._composeUrl(apiPath,data)
        data['apikey']=self.apiKey
        if self.sessionToken!=None:
            data['session_token']=self.sessionToken
        if type(data)==type({}):
            strData=urllib.urlencode(data)
        else:
            strData=str(data)
        dicHeaders['Accept-Encoding']='gzip'
        if method=='POST':
            req=urllib2.Request(url,data=strData,headers=dicHeaders)
        elif method=='GET':
            req=urllib2.Request(url+'?'+strData,headers=dicHeaders)
        else:
            raise RuntimeError('HTTP {} is not supported'.format(method))
        if type(data)==type({}):
            logging.debug('{} {} {}'.format(method, url, strData))
        else:
            logging.debug('{} {} {}'.format(method, url, `data`))
        try:
            start=time.time()
            f=self.opener.open(req, timeout=self.defaultTimeout)
        except urllib2.HTTPError,e:
            if e.code in (400,401,405,408,302):
                if e.code==302:
                    logging.debug('headers: %s',e.headers)
                f=e.fp
            else:
                raise
        finally:
            xResponseTime = 'x-response-time: %s'%f.info().get('x-response-time','')
            logging.debug('request "%s" spent %.3f seconds, %s',apiPath, time.time()-start, xResponseTime)
        logging.debug('response headers:')    
        prettyOutput(f.headers.dict,logging.debug)
        if f.info().get('Content-Encoding') == 'gzip':
            zData=f.read()
            buf = StringIO(zData)
            data=gzip.GzipFile(fileobj=buf).read()
            logging.debug('compression ratio: %s:%s',len(data),len(zData))
        else:
            data=f.read()
        if f.headers.dict.get('content-type')=='application/json':
            if len(data)>2000:
                logging.debug('%s %s',data[:2000], '(more...)')
            else:
                logging.debug(data)
            data=json.loads(data)
            self.apiRetCode = data['api_ret_code']
        return data

    def login(self, user, password):
        dic=self.httpPost(V2API.AUTH_LOGIN, {'email':user, 'password':password})
        if self.apiRetCode!=0:
            raise RuntimeError('login failed! %s'%dic['api_ret_message'])
        self.user=user
        self.password=password
        if dic['user']['state']!='registered':
            logging.warn('user need to install station first!')
        self.sessionToken=dic['session_token']
        self.userId=dic['user']['user_id']
        self.lstGroup=dic['groups']
        self.groupId=self.lstGroup[0]['group_id']

    def findStation(self):
        dic=self.httpPost(V2API.USERS_FIND_MY_STATION, {})
        if 'stations' in dic and dic['stations']:
            dicStation=dic['stations'][0]
            if 'location' in dicStation: 
                self.station=str(dicStation['location'])
            if 'public_location' in dicStation:
                self.stationPublic=str(dicStation['public_location'])
        return dic['stations']

    def getUserTotalPostId(self):
        dicData={'limit':10000 ,'group_id':self.groupId}
        dic=self.httpPost(V2API.POSTS_GET_LATEST, dicData)
        if self.apiRetCode!=0:
            raise RuntimeError('getLatest failed! %s'%dic['api_ret_message'])
        lstPostId=[]
        for d in dic['posts']:
            lstPostId.append(d['post_id'])
        lstPostId.reverse()
        return lstPostId

    def getUserTotalPostNumber(self):
        dic=self.httpPost(V2API.POSTS_GET_LATEST,{'limit':1,'group_id':self.groupId})
        if self.apiRetCode!=0:
            raise RuntimeError('get total posts number failed! %s'%dic['api_ret_message'])
        return dic['total_count']

    def setLastScan(self, index):
        lstPostId=self.getUserTotalPostId()
        if index>len(lstPostId):
            raise RuntimeError('specified index exceeds total post number')
        if index>0:
            index-=1
        elif index<0:
            index=len(lstPostId)+index
        else:
            raise RuntimeError('index cannot be 0')
        dicData={'post_id':lstPostId[index],'group_id':self.groupId}
        dic=self.httpPost(V2API.FOOTPRINTS_SET_LAST_SCAN, dicData)
        if self.apiRetCode!=0:
            raise RuntimeError('setLastScan failed! %s'%dic['api_ret_message'])
        if dic['last_scan']['post_id']!=lstPostId[index]:
            lastScanIndex=lstPostId.index(dic['last_scan']['post_id'])+1
            raise RuntimeError('you must specify an index bigger than %s'%lastScanIndex)
        logging.info('Set last-scan to %sth post %s', index+1, lstPostId[index])
        
    def getLastScan(self):
        dic=self.httpPost(V2API.FOOTPRINTS_GET_LAST_SCAN, {'group_id':self.groupId})
        if self.apiRetCode!=0:
            raise RuntimeError('getLastScan failed! %s'%dic['api_ret_message'])
        if not dic['last_scan']:
            logging.info('no last scan.')
            return
        return dic['last_scan']['post_id']
    
    def getPost(self, postId, contentOnly=0):
        dicData={'post_id':postId,'group_id':self.groupId}
        if contentOnly:        
            dicData['component_options']=json.dumps(['content'])
        dic=self.httpPost(V2API.POSTS_GET_SINGLE, dicData)
        if self.apiRetCode!=0:
            raise RuntimeError('get post failed! %s'%dic['api_ret_message'])
        return dic['post']
        
    def signupStation(self,stationId,location,publicLocation):
        dicData={'station_id':stationId, 'email':self.user, 'password':self.password}
        dic=self.httpPost(V2API.STATIONS_LOGON, dicData)
        if self.apiRetCode!=0:
            raise RuntimeError('signup failed! %s'%dic['api_ret_message'])
        return dic

    def getPostIndex(self, postId):
        lstPostId=self.getUserTotalPostId()
        return lstPostId.index(postId)+1

    def createTextPost(self, content):
        dicData={'content':content, 'type':'text','group_id':self.groupId}
        dic=self.httpPost(V2API.POSTS_NEW, dicData)
        return dic
        
    def createPhotoPost(self, content, lstPhotos):
        attachment_id_array=[]
        for i,(filePath,mimeType) in enumerate(lstPhotos):
            fPath,fName=os.path.split(filePath) 
            dicData={'group_id':self.groupId,
                     'title':convertToUtf8(fName),
                     'description':'',
                     'type':'image',
                     'image_meta':'origin',
                     }
            dic=self.multiPartPost('/attachments/upload', dicData, [('%00d_%s'%(i,fName), file(filePath,'rb'), mimeType)])
            if self.apiRetCode!=0:
                logging.error('upload "%s" failed. %s',fName, dic['api_ret_message'])
                return dic
            else:
                logging.info('upload "%s" successfully', fName)
                attachment_id_array.append(dic['object_id'])
        if not attachment_id_array:
            logging.warn('no image file found in %s', photoDir)
            return
        dicData={'attachment_id_array':json.dumps(attachment_id_array), 'content':content, 'type':'image', 'group_id':self.groupId}
        dic=self.httpPost('/posts/new', dicData)
        return dic

class BaseCommand(object):
    def __init__(self, objWfClient):
        self.objWfClient=objWfClient
    def __call__(self, *lstArgs, **dicArgs):
        logging.info('run %s(%s)',self.__class__.__name__, ', '.join(list([`x` for x in lstArgs]) + ['%s=%s'%(k,`v`)for k, v in dicArgs.items()]))
        self.run(self.objWfClient, *lstArgs, **dicArgs)

class GetTotalPostId(BaseCommand):
    def run(selfself, objWfClient):
        lst=objWfClient.getUserTotalPostId()
        logging.info('total post id:')
        for i,pid in enumerate(lst):
            logging.info('%03d %s',i,pid)

class GetLastScan(BaseCommand):
    def run(self, objWfClient):
        logging.info('total posts of user: %s', objWfClient.getUserTotalPostNumber())
        postId=objWfClient.getLastScan()
        if postId:
            logging.info('last-scan post id: %s',postId)
            logging.info('post index: %s', objWfClient.getPostIndex(postId))
            logging.info('Part of Content: %s...', objWfClient.getPost(postId,1)['content'][:50])
        else:
            logging.info('last-scan is not set')

class SetLastScan(BaseCommand):
    def run(self, objWfClient, index):
        index=int(index)
        lstPostId=objWfClient.getUserTotalPostId()
        if index>len(lstPostId):
            raise RuntimeError('specified index exceeds total post number')
        if index>0:
            index-=1
        elif index<0:
            index=len(lstPostId)+index
        else:
            raise RuntimeError('index cannot be 0')
        dicData={'post_id':lstPostId[index],'group_id':objWfClient.groupId}
        dic=objWfClient.httpPost('/footprints/setLastScan', dicData)
        if objWfClient.apiRetCode!=0:
            raise RuntimeError('setLastScan failed! %s'%dic['api_ret_message'])
        if dic['last_scan']['post_id']!=lstPostId[index]:
            lastScanIndex=lstPostId.index(dic['last_scan']['post_id'])+1
            raise RuntimeError('you must specify an index bigger than %s'%lastScanIndex)
        logging.info('Set last-scan to %sth post %s', index+1, lstPostId[index])

class findStation(BaseCommand):
    def run(self, objWfClient):
        lstStations=objWfClient.findStation()
        if not lstStations:
            logging.info('no station')
        else:
            for station in lstStations:
                logging.info('station:')
                for k,v in station.items():
                    logging.info('  {}: {}'.format(k,v))

class GetPost(BaseCommand):
    def run(self, objWfClient, id):
        if id.isdigit() or id[0]=='-':
            id=int(id)
            lstId=objWfClient.getUserTotalPostId()
            if id>0:
                id-=1
            id=lstId[id]
            print id
        post=objWfClient.getPost(id)
        logging.info('id: %s',post['post_id'])
        prettyOutput(post, logging.info)
        return

class GetLatest(BaseCommand):
    def run(self, objWfClient, limit):
        limit=int(limit)
        dic=objWfClient.httpPost(V2API.POSTS_GET_LATEST,{'limit':limit, 'group_id':objWfClient.groupId})
        logging.info('numOfPosts: %s',len(dic['posts']))
        prettyOutput(dic['posts'], logging.info)
        return


class CreatePost(BaseCommand):
    def __buildPhotoList(self, photoDir):
        lstPhoto=[]
        for fName in os.listdir(photoDir):
            mimeType=mimetypes.guess_type(fName)[0]
            if not mimeType:
                logging.debug('unknown file type "%s"',fName)
                continue
            if not mimeType.startswith('image'):
                continue        
            lstPhoto.append((fName,mimeType))
        return lstPhoto

    def run(self, objWfClient, count, textOnly=None, photoOnly=None, galleryFolder=None, postRepository='posts.json'):
        count=int(count)
        objWfClient.findStation()
        base=objWfClient.getUserTotalPostNumber()
        logging.info('user already has %s posts, start to create another %s posts',base,count)
        if photoOnly: lstPostType=[objWfClient.createPhotoPost]
        elif textOnly: lstPostType=[objWfClient.createTextPost]
        else: lstPostType=[objWfClient.createPhotoPost, objWfClient.createTextPost, objWfClient.createTextPost]

        lstGallery=self.__buildPhotoList(galleryFolder) if not textOnly and galleryFolder else []
        lstPostRepo=json.load(file(postRepository))
        for i in range(1,count+1):
            f=random.choice(lstPostType)
            if f == objWfClient.createTextPost:
                dicPost=random.choice(lstPostRepo)
                content=convertToUtf8('[%03d] %s\n\n%s %s'%(base+i,dicPost['content'],dicPost['creator'],dicPost['timestamp']))
                lstArgs=(content,)
            else:
                lstUpload=[(os.path.join(galleryFolder,photoName),mimeType) for (photoName,mimeType) in lstGallery]
                content='[%03d] This post has %s photos'%(base+i,len(lstUpload))
                lstArgs=(content, lstUpload)
            start=time.time()    
            dic=f(*lstArgs)
            if objWfClient.apiRetCode==0:
                logging.info('create the %s-th post success. id: %s',i,dic['post']['post_id'])
            else:
                logging.error('create the %s-th photo post fail. %s',i,dic['api_ret_message'])
                return
            end=time.time()-start
            if end<1 and count-i:
                logging.info('remain %s, cooldown %.2f second...',count-i,(1-end))
                time.sleep(1-end)
            else:
                logging.info('remain %s',count-i)

class SignupStation(BaseCommand):
    def run(self, objWfClient):
        dic=objWfClient.signupStation(str(uuid.uuid4()), 'http://192.168.0.168:9981','http://220.133.12.74:12345')
        prettyOutput(dic['station'],logging.info)

class GetPreview(BaseCommand):
    def run(self, objWfClient, url):
        dic=objWfClient.httpPost(V2API.PREVIEWS_GET,{'url':url})
        prettyOutput(dic['preview'],logging.info)

def prettyOutput(obj, out, prefix='  '):
    if isinstance(obj,dict):
        for k in sorted(obj.keys()):
            if not isinstance(obj[k],(dict,list,tuple)):
                out('{}{}: {}'.format(prefix, k, convertToUtf8(obj[k])))
            else:
                out('{}{}:'.format(prefix,k))
                prettyOutput(obj[k],out,prefix+'  ')
    elif isinstance(obj,(list,tuple)):
        for index,x in enumerate(obj):
            index+=1
            if not isinstance(x,(dict,list,tuple)):
                out('{}{}: {}'.format(prefix, index, convertToUtf8(x)))
            else:
                out('{}{}:'.format(prefix, index))
                prettyOutput(x,out,prefix+'  ')
    else:
        out('{}{}'.format(prefix,convertToUtf8(obj)))

g_dicCmds={}
for name,object in locals().items():
    if object!=BaseCommand and type(object)==types.TypeType and issubclass(object, BaseCommand):
        g_dicCmds[name[:1].lower()+name[1:]]=object

def main():
    logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s',level=logging.INFO)
    
    cmdParser=argparse.ArgumentParser(description='Waveface Test Utility')
    # Add optional switches
    cmdParser.add_argument('-v', action='store_true', dest='is_verbose', help='produce verbose output')
    #cmdParser.add_argument('-f', dest='cfg', metavar='CONFIG_FILE', help='specify a configuration file')
    cmdParser.add_argument('-u', dest='user', metavar='EMAIL', help='Waveface account')
    cmdParser.add_argument('-p', dest='passwd', metavar='PASSWORD', help='Waveface password')
    cmdParser.add_argument('-s', dest='server', metavar='SERVER', default='https://develop.waveface.com', help='http://ip:port of Waveface API Server')
    cmdParser.add_argument('command', action='store', metavar='command', choices=g_dicCmds.keys(), nargs=1, help=' | '.join(g_dicCmds.keys()))
    cmdParser.add_argument('arguments', action='store', metavar='arguments', default=[], nargs="*", help='additional arguments')

    args = cmdParser.parse_args()
    logging.info('Server: %s',args.server)
    client=WfClient(args.server, None, defaultTimeout=60)
    klass=g_dicCmds[args.command[0]]
    client.login(args.user, args.passwd)
    if args.is_verbose:
        logging.getLogger().setLevel(logging.DEBUG)    
    klass(client)(*args.arguments)

if __name__=='__main__':
    main()
