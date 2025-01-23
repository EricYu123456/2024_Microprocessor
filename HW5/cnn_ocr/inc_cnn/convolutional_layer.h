#pragma once
// =============================================================================
//  Program : activation_function.h
//  Author  : Chang-Jyun Liao
//  Date    : July/14/2024
// -----------------------------------------------------------------------------
//  Description:
//      This file defines the convolutional layer for the CNN models.
// -----------------------------------------------------------------------------
//  Revision information:
//  Dec/3/2024, by Chang-Jyun Liao:
//      Re-write the padding and forwarding function to increase performance.
// -----------------------------------------------------------------------------
//  License information:
//
//  This software is released under the BSD-3-Clause Licence,
//  see https://opensource.org/licenses/BSD-3-Clause for details.
//  In the following license statements, "software" refers to the
//  "source code" of the complete hardware/software system.
//
//  Copyright 2024,
//                    Embedded Intelligent Systems Lab (EISL)
//                    Deparment of Computer Science
//                    National Yang Ming Chiao Tung University
//                    Hsinchu, Taiwan.
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors
//     may be used to endorse or promote products derived from this software
//     without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// =============================================================================


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "layer.h"
#include "list.h"
#include "util.h"
#include "activation_function.h"

enum padding{
    valid,
    same
};

typedef struct _convolutional_layer
{
    layer_base base;
    index3d in_;
    index3d in_padded_;
    index3d out_;
    index3d weight_;
    index3d padding_;
    enum padding pad_type_;
    uint64_t w_stride_;
    uint64_t h_stride_;
    uint8_t has_bias_;

    uint64_t padding_done_flag;
    uint64_t padding_mask;
} convolutional_layer;

convolutional_layer * get_convolutional_layer_entry(struct list_node *ptr)
{
    return list_entry(ptr, convolutional_layer, base.list);
}

static uint64_t in_length(uint64_t in_length, uint64_t padding_size, enum padding pad_type)
{
    return pad_type == same ? in_length + 2 * padding_size : in_length;
}

static uint64_t conv_out_length(uint64_t in_length, uint64_t window_size, uint64_t padding_size, uint64_t stride, enum padding pad_type)
{
    return pad_type == same ?
               (int)(((float_t)in_length + 2 * padding_size - window_size) / stride) + 1 :
               (uint64_t) no_math_ceil((float_t)(in_length - window_size + 1) / stride);
}

static uint64_t conv_out_dim(uint64_t in_width, uint64_t in_height, uint64_t window_width,  uint64_t window_height, uint64_t w_padding, uint64_t h_padding, uint64_t w_stride, uint64_t h_stride, enum padding pad_type)
{
    return conv_out_length(in_width, window_width, w_padding, w_stride, pad_type) * conv_out_length(in_height, window_height, h_padding, h_stride, pad_type);
}

void conv_copy_and_pad_input(convolutional_layer *entry, input_struct *input)
{
    if (entry->pad_type_ == same)
    {
        index3d in_ = entry->in_;
        index3d in_padded_ = entry->in_padded_;
        index3d padding_ = entry->padding_;

        uint64_t c = 0;
        uint64_t y = 0;

        float_t *in = input->in_ptr_;
        float_t *dst = entry->base.padded_ptr;
        uint64_t total_size = in_.depth_ * in_.height_;

        for (uint64_t i = 0; i < total_size; i++)
        {
            float_t *pimg = &dst[get_index(&in_padded_, padding_.width_, padding_.height_ + y, c)];
            const float_t *pin = &in[get_index(&in_, 0, y, c)];

            for (uint64_t x = 0; x < in_.width_; x++)
            {
                pimg[x] = pin[x];
            }
            
            y++;
            if (y == in_.height_)
            {
                y = 0;
                c++;
            }
        }
    }
}

// void conv_3d(uint64_t o, convolutional_layer *entry, float_t *pa)
// { // 將權重矩陣 𝑊 與輸入數據 in 卷積後的結果累加到輸出數據 𝑝𝑎 中
//     float_t *W = entry->base._W;
//     // int *W_32 = entry->base._W;
//     float_t *in = entry->base.padded_ptr;
//     index3d in_ = entry->in_;
//     index3d out_ = entry->out_;
//     index3d in_padded_ = entry->in_padded_;
//     index3d weight_ = entry->weight_;
//     uint64_t h_stride_ = entry->h_stride_;
//     uint64_t w_stride_ = entry->w_stride_;
//     const uint64_t const1 = in_padded_.width_ - weight_.width_;
//     const uint64_t const2 = h_stride_ * in_padded_.width_ - out_.width_ * w_stride_;
//     // printf("----------------------------\n");
//     // for(int i = 0 ; i < 2375 + 25 ; i ++){
//     //     printf("%x, ",W_32[i]);
//     // }
//     // printf("----------------------------\n");
//     // printf("----------------------------\n");
//     // printf("----------------------------\n");
//     // printf("----------------------------\n");
//     // printf("----------------------------\n");
//     // printf("----------------------------\n");
//     for (uint64_t inc = 0; inc < in_.depth_; inc++) {// 1 or 3
//         const float_t *pw = &W[get_index(&weight_, 0, 0, in_.depth_ * o + inc)];
//         // if((int)get_index(&weight_, 0, 0, in_.depth_ * o + inc) > 2375){
//         //    printf("%d, ", (int)get_index(&weight_, 0, 0, in_.depth_ * o + inc)); 
//         // }
//         // Convert repeatedly calculated numbers to constants.
//         float_t * ppi = &in[get_index(&in_padded_, 0, 0, inc)];
//         uint64_t idx = 0;
//         const uint64_t inner_loop_iter = weight_.height_ * weight_.width_; // 固定25
//         for (uint64_t y = 0; y < out_.height_; y++) {
//             for (uint64_t x = 0; x < out_.width_; x++) { // 24*24 8*8
//                 const float_t * ppw = pw;
//                 float_t sum = (float_t)0;
//                 uint64_t wx = 0, widx = 0;
//                 for (uint64_t wyx = 0; wyx < inner_loop_iter; wyx++) { // 固定25
//                     // printf("%f * %f", *ppw, ppi[widx]);
//                     //if((int)wyx == 24) printf("%f, ",(*ppw * ppi[widx]));
//                     sum += *ppw++ * ppi[widx];
                    
//                     wx++;
//                     widx++;
//                     if (wx == weight_.width_)
//                     {
//                         wx = 0;
//                         widx += const1; // 23 or 7
//                     }
//                 }
//                 // printf("(%d,%f), ", (int)idx, sum);
//                 pa[idx++] += sum;
//                 ppi += w_stride_;
//             }
//             ppi += const2;
//         }
//     }
// }
void conv_3d(uint64_t o, convolutional_layer *entry, float_t *pa)
{ // 將權重矩陣 𝑊 與輸入數據 in 卷積後的結果累加到輸出數據 𝑝𝑎 中
    // printf("=========================================================\n");
    // printf("=========================================================\n");
    // printf("=========================================================\n");
    volatile float_t *W = (volatile float_t *)entry->base._W;
    // printf("W:  %04x, ",W);
    float_t *in = entry->base.padded_ptr;
    index3d in_ = entry->in_;
    index3d out_ = entry->out_;
    index3d in_padded_ = entry->in_padded_;
    index3d weight_ = entry->weight_;
    uint64_t h_stride_ = entry->h_stride_;
    uint64_t w_stride_ = entry->w_stride_;
    const uint64_t const1 = in_padded_.width_ - weight_.width_;
    const uint64_t const2 = h_stride_ * in_padded_.width_ - out_.width_ * w_stride_;

    //const uint64_t total_elements = in_padded_.height_ * in_padded_.width_ * in_padded_.depth_;
    // volatile uint32_t *target_num_reg = (uint32_t *)0xC4040000;
    // volatile uint32_t *w_st_reg = (uint32_t *)0xC4040004;
    //volatile uint32_t *ppi_st_reg = (uint32_t *)0xC4040008;
    //volatile uint32_t *const1_reg = (uint32_t *)0xC404000c;
    volatile uint32_t *ret_mode_reg = (uint32_t *)0xC4040010;
    volatile float_t *ans_store_reg = (float_t *)0xC4040014;
    // *target_num_reg = total_elements;
    // 定義一個 volatile 指針，對應硬體中的 RAM
    volatile float_t *hardware_ram = (volatile float_t *)0xC4050000;
    volatile float_t *weight_ram = (volatile float_t *)0xC4070000;
    int in_idx = 0;
    // 將所有 `in` 元素存入硬體 RAM
    // for (uint64_t i = 0; i < total_elements; i++) {
    //     hardware_ram[i] = in[i];
    // }
    for (uint64_t inc = 0; inc < in_.depth_; inc++) {// 1 or 3
        // const float_t *pw = &W[get_index(&weight_, 0, 0, in_.depth_ * o + inc)];
        //*ret_mode_reg = 0;
        int w_st = (int)get_index(&weight_, 0, 0, in_.depth_ * o + inc);
        for(int i = 0 ; i < 25 ; i ++){
            weight_ram[i] = W[w_st + i];
        }
        //*w_st_reg = (uint32_t)get_index(&weight_, 0, 0, in_.depth_ * o + inc); // w_st 給 hardware
        // HW loaing 25 weights
        // Convert repeatedly calculated numbers to constants.
        // float_t * ppi = &in[get_index(&in_padded_, 0, 0, inc)];
        int ppi_st = get_index(&in_padded_, 0, 0, inc);

        uint64_t idx = 0;
        // const uint64_t inner_loop_iter = weight_.height_ * weight_.width_; // 固定25
        for (uint64_t y = 0; y < out_.height_; y++) {
            for (uint64_t x = 0; x < out_.width_; x++) { // 24*24 8*8
                // HW loaing 25 ins
                //*ret_mode_reg = 1;
                // load ppist
                for( in_idx = 0; in_idx < 5; in_idx ++){
                    hardware_ram[in_idx] = in[ppi_st + in_idx];
                }
                for( in_idx = 5; in_idx < 10; in_idx ++){
                    hardware_ram[in_idx] = in[ppi_st + in_idx + const1];
                }
                for( in_idx = 10; in_idx < 15; in_idx ++){
                    hardware_ram[in_idx] = in[ppi_st + in_idx + const1*2];
                }
                for( in_idx = 15; in_idx < 20; in_idx ++){
                    hardware_ram[in_idx] = in[ppi_st + in_idx + const1*3];
                }
                for( in_idx = 20; in_idx < 25; in_idx ++){
                    hardware_ram[in_idx] = in[ppi_st + in_idx + const1*4];
                }
                
                // hardware_ram[24] = 0;
                // const float_t * ppw = pw;
                // float_t sum = (float_t)0;
                // uint64_t wx = 0, widx = 0;
                
                // *ppi_st_reg = ppi_st; // ppi_st 給 hardware
                // *const1_reg = const1; // const1 給 hardware
                // for (uint64_t wyx = 0; wyx < inner_loop_iter; wyx++) { // 固定25
                //     sum += *ppw++ * ppi[widx];
                //     wx++;
                //     widx++;
                //     if (wx == weight_.width_)
                //     {
                //         wx = 0;
                //         widx += const1; // 23 or 7
                //     }
                // }
                
                // printf("(%d,%f), ", (int)idx, aaa);
                
                pa[idx++] += *ans_store_reg;
                //if(aaa != sum)printf("(%d,%f,%f), ",(int)idx,aaa,sum);
                // ppi += w_stride_;
                ppi_st += w_stride_;
                // printf("%d %d %d\n",(int)out_.width_,(int)out_.height_,(int)in_.depth_);
                
                if((x == out_.width_ - 1) && (y == out_.height_ - 1)) *ret_mode_reg = 0;
                else *ret_mode_reg = 1;
                
            }
            // ppi += const2;
            ppi_st += const2;
        }
    }
}
void convolutional_layer_forward_propagation(struct list_node *ptr, input_struct *input)
{
    convolutional_layer *entry = get_convolutional_layer_entry(ptr);
    if (input->in_size_ != entry->base.in_size_)
    {
        printf("Error input size not match %lu/%lu\n", input->in_size_, entry->base.in_size_);
        exit(-1);
    }
    conv_copy_and_pad_input(entry, input);

    float_t *a = entry->base.a_ptr_;
    float_t *b = entry->base._b;
    float_t *out = entry->base.out_ptr_;
    input->in_ptr_ = out;
    input->in_size_ = entry->base.out_size_;
    index3d out_ = entry->out_;
    uint64_t total_size = out_.depth_;
    uint64_t out_dim = out_.height_*out_.width_;

    for (uint64_t o = 0; o < total_size; o++)
    {
        float_t *pa = &a[get_index(&out_, 0, 0, o)];
        memset((void*)pa, 0, out_dim *sizeof(float_t));

        conv_3d(o, entry, pa);

        if (entry->has_bias_) {
            for (uint64_t index = 0; index < out_dim; index++)
                pa[index] += b[o];
        }
    }

    total_size = entry->base.out_size_;

    for (uint64_t c = 0; c < total_size; c++)
        out[c] = entry->base.activate(a, c, entry->base.out_size_);
    
#ifdef PRINT_LAYER
    printf("[%s] done [%f, %f, ... , %f, %f]\n", entry->base.layer_name_, out[0], out[1], out[entry->base.out_size_-2], out[entry->base.out_size_-1]);
#endif
}

layer_base * new_convolutional_layer(
                                     cnn_controller *ctrl,
                                     float_t(*activate) (float_t *, uint64_t, uint64_t),
                                     uint64_t in_width,
                                     uint64_t in_height,
                                     uint64_t window_width,
                                     uint64_t window_height,
                                     uint64_t in_channels,
                                     uint64_t out_channels,
                                     enum padding  pad_type,
                                     uint8_t  has_bias,
                                     uint64_t w_stride,
                                     uint64_t h_stride,
                                     uint64_t w_padding,
                                     uint64_t h_padding
                                    )
{
    convolutional_layer *ret = (convolutional_layer *)malloc(sizeof(convolutional_layer));

    if (pad_type == same)
        ctrl->padding_size = in_length(in_width, w_padding, pad_type) * in_length(in_height, h_padding, pad_type) * in_channels;
    else 
        ctrl->padding_size = 0;
        
    init_layer(&ret->base,
               ctrl,
               in_width*in_height*in_channels,
               conv_out_dim(in_width, in_height, window_width, window_height, w_padding, h_padding, w_stride, h_stride, pad_type) * out_channels, 
               window_width * window_height * in_channels * out_channels,
               has_bias ? out_channels : 0,
               activate==relu
              );
#ifdef PRINT_LAYER
    static uint64_t call_time = 0;
    sprintf(ret->base.layer_name_, "conv%lu", call_time++);
#endif
    ret->in_ = new_index3d(in_width, in_height, in_channels);
    ret->in_padded_ = new_index3d(in_length(in_width, w_padding, pad_type), in_length(in_height, h_padding, pad_type), in_channels);
    ret->out_ = new_index3d(conv_out_length(in_width, window_width, w_padding, w_stride, pad_type), conv_out_length(in_height, window_height, h_padding, h_stride, pad_type), out_channels);
    ret->weight_ = new_index3d(window_width, window_height, in_channels*out_channels);
    ret->padding_ = new_index3d(w_padding, h_padding, 0);
    ret->pad_type_ = pad_type;
    ret->w_stride_ = w_stride;
    ret->h_stride_ = h_stride;
    ret->has_bias_ = has_bias;

    ret->base.activate = activate;
    ret->base.forward_propagation = convolutional_layer_forward_propagation;
    // printf("insize of average pooling layer %d\n", ret->base.in_size_);
#ifdef PRINT_LAYER
    printf("conv: W [%f, %f, ... , %f, %f]\n", ret->base._W[0], ret->base._W[1], ret->base._W[window_width * window_height * in_channels * out_channels-2], ret->base._W[window_width * window_height * in_channels * out_channels-1]);
#endif
    // printf("conv: in [%f, %f, ... , %f, %f]\n", ret->base.in_ptr_[0], ret->base.in_ptr_[1], ret->base.in_ptr_[ret->base.in_size_-2], ret->base.in_ptr_[ret->base.in_size_-1]);
    // printf("conv: b  [%f, %f, ... , %f, %f]\n", ret->base._b[0], ret->base._b[1], ret->base._b[in_channels-2], ret->base._b[in_channels-1]);
    return &ret->base;
}
