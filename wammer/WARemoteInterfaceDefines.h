//
//  WARemoteInterfaceDefines.h
//  wammer
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

//	github://waveface/Wammer-Cloud/AP-Server/wfcloud/util/error.py

extern NSString *kWARemoteInterfaceDomain;
extern void WARemoteInterfaceNotPorted (void);
extern NSUInteger WARemoteInterfaceEndpointReturnCode (NSDictionary *response);
extern NSString * WARemoteInterfaceEndpointReturnMessage (NSDictionary *response);
extern NSError * WARemoteInterfaceGenericError (NSDictionary *response, NSDictionary *context);
extern IRWebAPICallback WARemoteInterfaceGenericFailureHandler (void(^aFailureBlock)(NSError *));
extern IRWebAPIResposeValidator WARemoteInterfaceGenericNoErrorValidator (void);

extern NSString *kWARemoteInterfaceUnderlyingError;	//	Populated error from IRWebAPIEngine context
extern NSString *kWARemoteInterfaceUnderlyingContext;	//	The IRWebAPIEngine context where the aforementioned error 
extern NSString *kWARemoteInterfaceRemoteErrorCode;	//	Populated error from WFCloud defined in WARemoteInterfaceDefines

extern NSDictionary *WARemoteInterfaceRFC3986EncodedDictionary (NSDictionary *encodedDictionary);

extern NSDictionary *WARemoteInterfaceEnginePostFormEncodedOptionsDictionary (NSDictionary *parameters, NSDictionary *mergedOtherOptionsOrNil);

enum {
	
	WASuccess = 0,
	WAUnknownException = 1,
	WAInvalidParameters = 2,
	WADatabaseError = 3,
	WAInvalidClass = 4,
	WAInvalidAction = 5,
	WAPermissionDenied = 6,
	WAInvalidFile = 7,
	WAInternalError = 8,
	
	WAAuthBase = 0x00001000,
	WAProspectiveUserIsInvalid = WAAuthBase + 1,
	WAProspectiveUserAlreadyRegistered = WAAuthBase + 2,
	
	WAUserBase = 0x00002000,
	WARequestedUserDoesNotExist = WAUserBase + 1,
	WAUserRequestInvalid = WAUserBase + 2,
	WAUserRequestWasDenied = WAUserBase + 3,
	
	WAPostBase = 0x00003000,
	WARequestedPostDoesNotExist = WAPostBase + 1,
	WAPostRequestInvalid = WAPostBase + 2,
	WAPostRequestWasDenied = WAPostBase + 3,
	
	WAStationBase = 0x00004000,
	WARequestedStationDoesNotExist = WAStationBase + 1,
	WAProspectiveStationIsRegistered = WAStationBase + 2,
	
	WAGroupBase = 0x00005000,
	WARequestedGroupDoesNotExist = WAGroupBase + 1,
	WAProspectiveGroupAlreadyRegistered = WAGroupBase + 2,
	WAGroupRequestWasDenied = WAGroupBase + 3,
	WAGroupDoesNotContainMember = WAGroupBase + 4,
	WAGroupAlreadyContainsMember = WAGroupBase + 5,
	WAGroupDriverRemovalIsDenied = WAGroupBase + 6,
	
	WAAttachmentBase = 0x00006000,
	WAAttachmentDoesNotExist = WAAttachmentBase + 1,
	WAAttachmentTypeNotSupported = WAAttachmentBase + 2,
	WAAttachmentDocumentNotSupported = WAAttachmentBase + 3,
	WAAttachmentS3UploadFailed = WAAttachmentBase + 4,
	WAAttachmentS3DownloadFailed = WAAttachmentBase + 5,
	WAAttachmentMicrosoftOfficeFileConversionFailed = WAAttachmentBase + 6,
	WAAttachmentValueInvalid = WAAttachmentBase + 7,
	WAAttachmentInternalError = WAAttachmentBase + 8,
	WAAttachmentLOCInvalid = WAAttachmentBase + 9,
	WAAttachmentImagesInvalid = WAAttachmentBase + 10,
	WAAttachmentQuotaExceeded = WAAttachmentBase + 11,
	WAAttachmentPermissionDenied = WAAttachmentBase + 12,
	WAAttachmentMetatypeInvalid = WAAttachmentBase + 13,
	WAAttachmentOriginalFileExists = WAAttachmentBase + 14,
	
	WAApplicationKeyBase = 0x00007000,
	WAApplicationKeyDoesNotExist = WAApplicationKeyBase + 1,
	
	WAPreviewBase = 0x00008000,
	WAPreviewDoesNotExist = WAPreviewBase + 1,
	WAPreviewURLInvalid = WAPreviewBase + 2,
	
	WAFootprintBase = 0x00009000,
	WAFootprintPostIdentifiersInvalid = WAFootprintBase + 1,
	WAFootprintLastReadInputsInvalid = WAFootprintBase + 2,
	
	WAS3StoreBase = 0x0000a000,
	WAS3StoreCredentialsInvalid = WAS3StoreBase + 1,
	WAS3StoreBucketInvalid = WAS3StoreBase + 2
	
};
