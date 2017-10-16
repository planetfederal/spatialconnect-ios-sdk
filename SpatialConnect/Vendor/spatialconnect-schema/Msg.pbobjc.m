// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: proto/Msg.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers_RuntimeSupport.h>
#else
 #import "GPBProtocolBuffers_RuntimeSupport.h"
#endif

 #import "Msg.pbobjc.h"
// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - MsgRoot

@implementation MsgRoot

@end

#pragma mark - MsgRoot_FileDescriptor

static GPBFileDescriptor *MsgRoot_FileDescriptor(void) {
  // This is called by +initialize so there is no need to worry
  // about thread safety of the singleton.
  static GPBFileDescriptor *descriptor = NULL;
  if (!descriptor) {
    GPBDebugCheckRuntimeVersion();
    descriptor = [[GPBFileDescriptor alloc] initWithPackage:@""
                                                     syntax:GPBFileSyntaxProto3];
  }
  return descriptor;
}

#pragma mark - Msg

@implementation Msg

@dynamic context;
@dynamic correlationId;
@dynamic to;
@dynamic action;
@dynamic payload;
@dynamic jwt;

typedef struct Msg__storage_ {
  uint32_t _has_storage_[1];
  NSString *context;
  NSString *to;
  NSString *action;
  NSString *payload;
  NSString *jwt;
  int64_t correlationId;
} Msg__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "context",
        .dataTypeSpecific.className = NULL,
        .number = Msg_FieldNumber_Context,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(Msg__storage_, context),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "correlationId",
        .dataTypeSpecific.className = NULL,
        .number = Msg_FieldNumber_CorrelationId,
        .hasIndex = 1,
        .offset = (uint32_t)offsetof(Msg__storage_, correlationId),
        .flags = GPBFieldOptional | GPBFieldTextFormatNameCustom,
        .dataType = GPBDataTypeInt64,
      },
      {
        .name = "to",
        .dataTypeSpecific.className = NULL,
        .number = Msg_FieldNumber_To,
        .hasIndex = 2,
        .offset = (uint32_t)offsetof(Msg__storage_, to),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "action",
        .dataTypeSpecific.className = NULL,
        .number = Msg_FieldNumber_Action,
        .hasIndex = 3,
        .offset = (uint32_t)offsetof(Msg__storage_, action),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "payload",
        .dataTypeSpecific.className = NULL,
        .number = Msg_FieldNumber_Payload,
        .hasIndex = 4,
        .offset = (uint32_t)offsetof(Msg__storage_, payload),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "jwt",
        .dataTypeSpecific.className = NULL,
        .number = Msg_FieldNumber_Jwt,
        .hasIndex = 5,
        .offset = (uint32_t)offsetof(Msg__storage_, jwt),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[Msg class]
                                     rootClass:[MsgRoot class]
                                          file:MsgRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(Msg__storage_)
                                         flags:0];
#if !GPBOBJC_SKIP_MESSAGE_TEXTFORMAT_EXTRAS
    static const char *extraTextFormatInfo =
        "\001\002\r\000";
    [localDescriptor setupExtraTextInfo:extraTextFormatInfo];
#endif  // !GPBOBJC_SKIP_MESSAGE_TEXTFORMAT_EXTRAS
    NSAssert(descriptor == nil, @"Startup recursed!");
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end


#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
