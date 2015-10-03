
#import "ToneGenerator.h"
#import <AVFoundation/AVFoundation.h>

@interface ToneGenerator()

@property (nonatomic) double theta;
@property (nonatomic) double amplitude;
@property (nonatomic) AudioComponentInstance audioComponent;
@property (nonatomic) BOOL fadingIn;
@property (nonatomic) BOOL fadingOut;
@end

@implementation ToneGenerator

- (id)init;
{
    if (!(self = [super init])) { return nil; }
   
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    [AVAudioSession.sharedInstance setActive:YES error:nil];
    [self initializeAudioUnit];
    
   return self;
}

- (void)initializeAudioUnit;
{
    AudioComponentDescription outputDescription = { .componentType = kAudioUnitType_Output, .componentSubType = kAudioUnitSubType_RemoteIO, .componentManufacturer = kAudioUnitManufacturer_Apple, .componentFlags = 0, .componentFlagsMask = 0 };
    
    AudioComponent output = AudioComponentFindNext(NULL, &outputDescription);
    AudioComponentInstanceNew(output, &_audioComponent);
    
    AURenderCallbackStruct input = { .inputProc = Render, .inputProcRefCon = (__bridge void *)self };
    AudioUnitSetProperty(self.audioComponent, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, sizeof(AURenderCallbackStruct));
    
    AudioStreamBasicDescription streamFormat = {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
        .mSampleRate = 44100,
        .mBytesPerPacket = 4,
        .mBytesPerFrame = 4,
        .mFramesPerPacket = 1,
        .mChannelsPerFrame = 1,
        .mBitsPerChannel = 32};
    
    AudioUnitSetProperty (self.audioComponent, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(AudioStreamBasicDescription));
}

- (void)play;
{
    self.theta = 0;
    self.amplitude = 0;
    self.fadingIn = YES;
    self.fadingOut = NO;
    AudioOutputUnitStart(_audioComponent);
}

- (void)stop;
{
    self.fadingIn = NO;
    self.fadingOut = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        AudioOutputUnitStop(_audioComponent);
    });
}

OSStatus Render(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 						inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    ToneGenerator *toneGenerator = (__bridge ToneGenerator *)inRefCon;
    
    double theta = toneGenerator->_theta;
    double frequency = toneGenerator->_frequency;
    double thetaIncrement = 2.0 * M_PI * frequency / 44100;
    
    // Apply Fletcher-Munson curve.
    double amplitude = (1.f / sqrt(frequency)) * 5.f < 1.f ? (1.f / sqrt(frequency)) * 5.f : 1.f;
    amplitude *= 0.5;
    
    if (toneGenerator->_fadingIn) {
        toneGenerator->_amplitude += .005;
        if (toneGenerator->_amplitude > amplitude) {
            toneGenerator->_fadingIn = NO;
        }
        amplitude = toneGenerator->_amplitude;
    }
    
    Float32 *buffer = (Float32 *)ioData->mBuffers[0].mData;
    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
        if (toneGenerator->_fadingOut) {
            toneGenerator->_amplitude -= .0005;
            if (toneGenerator->_amplitude < 0.0) {
                toneGenerator->_amplitude = 0.0;
            }
            amplitude = toneGenerator->_amplitude;
        }
        buffer[frame] = sin(theta) * amplitude;
        theta += thetaIncrement;
        if (theta > 2.0 * M_PI) { theta -= 2.0 * M_PI; }
    }
    if (!toneGenerator->_fadingOut) {
        toneGenerator->_amplitude = amplitude;
    }
    toneGenerator->_theta = theta;
    return noErr;
}

@end
