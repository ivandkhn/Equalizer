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


// temp buffers to handle values that are close to AudioBuffer boundaries
// actually have to take approx. 800-1500 samples for buffering
const int BUFFER_LENGTH = 512; // TODO: inherit from actual buffer size
float bufferL[BUFFER_LENGTH];
float bufferR[BUFFER_LENGTH];
float *curr_in, *prev_in, *out;
int offset;

void ChoirDSP::process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) {
    offset = (int)_private->leftGainRamp.getValue();
    
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        int frameOffset = int(frameIndex + bufferOffset);
        if ((frameOffset & 0x7) == 0) {
            _private->leftGainRamp.advanceTo(_now + frameOffset);
            _private->rightGainRamp.advanceTo(_now + frameOffset);
        }
        
        for (int channel = 0; channel < _nChannels; ++channel) {
            if (frameIndex >= offset) {
                prev_in = (float *)_inBufferListPtr->mBuffers[channel].mData
                        + frameOffset - offset;
            } else {
                if (channel == 0) {
                    prev_in = &bufferL[BUFFER_LENGTH-1-offset+frameIndex];
                } else {
                    prev_in = &bufferR[BUFFER_LENGTH-1-offset+frameIndex];
                }
            }
            curr_in = (float *)_inBufferListPtr->mBuffers[channel].mData + frameOffset;
            out = (float *)_outBufferListPtr->mBuffers[channel].mData + frameOffset;
            *out = *prev_in + *curr_in;
            if (channel == 0) {
                //cout << *prev_in << " " << *curr_in << " " << *out << endl;
            }
        }
    }
    // TODO: memcpy ??
    for (int i=0; i<512; i++) {
        bufferL[i] = *((float *)_inBufferListPtr->mBuffers[0].mData + i);
        bufferR[i] = *((float *)_inBufferListPtr->mBuffers[1].mData + i);
    }
}


// first attempt

/*
float buffer[512];

void ChoirDSP::process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) {
    int offset = (int)_private->leftGainRamp.getValue();
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        assert(bufferOffset == 0);
        // do ramping every 8 samples
        if ((frameIndex & 0x7) == 0) {
            _private->leftGainRamp.advanceTo(_now + frameIndex);
            _private->rightGainRamp.advanceTo(_now + frameIndex);
        }
        for (int channel = 0; channel < _nChannels; ++channel) {
            if (frameCount >= offset) {
                float *curr_in = (float *)_inBufferListPtr->mBuffers[channel].mData + frameIndex;
                float *prev_in = (float *)_inBufferListPtr->mBuffers[channel].mData + frameIndex - offset;
                //                          ^ out -> in
                float *out = (float *)_outBufferListPtr->mBuffers[channel].mData + frameIndex;
                *out = *prev_in + *curr_in;
                buffer[frameIndex] = *curr_in;
            } else {
                float *curr_in = (float *)_inBufferListPtr->mBuffers[channel].mData + frameIndex;
                float *prev_in = &buffer[511-offset+frameIndex];
                float *out = (float *)_outBufferListPtr->mBuffers[channel].mData + frameIndex;
                *out = *prev_in + *curr_in;
                buffer[frameIndex] = *curr_in;
            }
        }
    }
}
*/
