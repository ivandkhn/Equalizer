//
//  ChoirDSP.mm
//  Equalizer
//
//  Created by Иван Дахненко on 05/03/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

#include "ChoirDSP.hpp"
#include <cmath>
#include <iostream>

using namespace std;

extern "C" void *createChoirDSP(int nChannels, double sampleRate) {
    ChoirDSP *dsp = new ChoirDSP();
    dsp->init(nChannels, sampleRate);
    return dsp;
}

struct ChoirDSP::_Internal {
    AKParameterRamp leftGainRamp;
    AKParameterRamp rightGainRamp;
};

ChoirDSP::ChoirDSP() : _private(new _Internal) {
    _private->leftGainRamp.setTarget(1.0, true);
    _private->leftGainRamp.setDurationInSamples(10000);
    _private->rightGainRamp.setTarget(1.0, true);
    _private->rightGainRamp.setDurationInSamples(10000);
}

// Uses the ParameterAddress as a key
void ChoirDSP::setParameter(AUParameterAddress address, AUValue value, bool immediate) {
    switch (address) {
        case AKBoosterParameterLeftGain:
            _private->leftGainRamp.setTarget(value, immediate);
            break;
        case AKBoosterParameterRightGain:
            _private->rightGainRamp.setTarget(value, immediate);
            break;
        case AKBoosterParameterRampDuration:
            _private->leftGainRamp.setRampDuration(value, _sampleRate);
            _private->rightGainRamp.setRampDuration(value, _sampleRate);
            break;
        case AKBoosterParameterRampType:
            _private->leftGainRamp.setRampType(value);
            _private->rightGainRamp.setRampType(value);
            break;
    }
}

// Uses the ParameterAddress as a key
float ChoirDSP::getParameter(AUParameterAddress address) {
    switch (address) {
        case AKBoosterParameterLeftGain:
            return _private->leftGainRamp.getTarget();
        case AKBoosterParameterRightGain:
            return _private->rightGainRamp.getTarget();
        case AKBoosterParameterRampDuration:
            return _private->leftGainRamp.getRampDuration(_sampleRate);
    }
    return 0;
}

const int BUFFER_LENGTH = 5000; //same is a maximum delay length in samples
float bufferL[BUFFER_LENGTH];
float bufferR[BUFFER_LENGTH];
float *curr_in_L, *curr_in_R, *prev_in, *outL, *outR;
unsigned int currentBufferPosition = 0;

void ChoirDSP::process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) {
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        int frameOffset = int(frameIndex + bufferOffset);
        if ((frameOffset & 0x7) == 0) {
            _private->leftGainRamp.advanceTo(_now + frameOffset);
            _private->rightGainRamp.advanceTo(_now + frameOffset);
        }
        
        outL = (float *)_outBufferListPtr->mBuffers[0].mData + frameOffset;
        outR = (float *)_outBufferListPtr->mBuffers[1].mData + frameOffset;
        curr_in_L = (float *)_inBufferListPtr->mBuffers[0].mData + frameOffset;
        curr_in_R = (float *)_inBufferListPtr->mBuffers[1].mData + frameOffset;
        
        *outL = *curr_in_L + bufferL[currentBufferPosition];
        *outR = *curr_in_R + bufferR[currentBufferPosition];
        
        bufferL[currentBufferPosition] = *curr_in_L;
        bufferR[currentBufferPosition] = *curr_in_R;
        
        //simplest ring buffer
        currentBufferPosition++;
        if (
            currentBufferPosition >= (int)_private->leftGainRamp.getValue()-1 ||
            // we can accidenlty run out of array boundaries using leftGainRamp.getValue,
            // so this condition prevents thread crash
            currentBufferPosition >= BUFFER_LENGTH-1
            ) {
            currentBufferPosition = 0;
        }
    }
}
