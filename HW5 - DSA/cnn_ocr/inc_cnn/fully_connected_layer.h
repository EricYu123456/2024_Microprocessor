#pragma once
// =============================================================================
//  Program : activation_function.h
//  Author  : Chang-Jyun Liao
//  Date    : July/14/2024
// -----------------------------------------------------------------------------
//  Description:
//      This file defines the fully connected layer for the CNN models.
// -----------------------------------------------------------------------------
//  Revision information:
//
//  None.
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
#include "config.h"
#include "layer.h"
#include "list.h"
#include "util.h"
#include "activation_function.h"

typedef struct _fully_connected_layer
{
    layer_base base;

    uint8_t has_bias_;
} fully_connected_layer;

fully_connected_layer * get_fully_connected_layer_entry(struct list_node *ptr)
{
    return list_entry(ptr, fully_connected_layer, base.list);
}

// void fully_connected_layer_forward_propagation(struct list_node *ptr, input_struct *input)
// {
//     // printf("call_func1\n");
//     fully_connected_layer *entry = get_fully_connected_layer_entry(ptr);
    
//     if (input->in_size_ != entry->base.in_size_)
//     {
//         printf("Error input size not match %lu/%lu\n", input->in_size_, entry->base.in_size_);
//         exit(-1);
//     }
//     float_t *in = input->in_ptr_;
//     float_t *a = entry->base.a_ptr_; 
//     float_t *W = entry->base._W; 
//     int *W_32 = entry->base._W;
//     float_t *b = entry->base._b; 
//     float_t *out = entry->base.out_ptr_; 

//     input->in_ptr_ = out;
//     input->in_size_ = entry->base.out_size_; 

//     int total_size = entry->base.out_size_;
    
//     // printf("\ntotal_size = %d ", total_size);
//     for (int i = 0; i < total_size; i++)
//     {
//         a[i] = (float_t)0;
//         // int kkk=entry->base.in_size_;
//         // printf("(base.in_size_=%d)\n",kkk);
//         // printf("in_size = %d ", (int)entry->base.in_size_);
//         for (uint64_t c = 0; c < entry->base.in_size_; c++){
//             // printf("st---------------------------------------\n");
//             int hex_val = W_32[i*entry->base.in_size_ + c];
//             float *float_ptr = (float *)&hex_val; 
//             // printf("%d:", (int)(i*512+c));
//             // printf("%x; ",hex_val);
//             // printf("[%d, %d]: %f * %f + %f\n", i, (int)c, W[i*entry->base.in_size_ + c], in[c], a[i]);
//             a[i] += W[i*entry->base.in_size_ + c] * in[c];
            
//         }
            
//         // printf("end---------------------------------------\n");
//         if (entry->has_bias_) 
//             a[i] += b[i];

//         //printf("a[%d]=%f\n", i, a[i]);
//     }
//     // 應用激活函數
//     for (uint64_t i = 0; i < total_size; i++)
//         out[i] = entry->base.activate(a, i, entry->base.out_size_);
//     //printf("----------------------------------------------------\n");
// #ifdef PRINT_LAYER
//     printf("[%s] done [%f, %f, ... , %f, %f]\n", entry->base.layer_name_, out[0], out[1], out[entry->base.out_size_-2], out[entry->base.out_size_-1]);
// #endif
// }

// void fully_connected_layer_forward_propagation(struct list_node *ptr, input_struct *input)
// {
//     // printf("call_func1 ");
//     fully_connected_layer *entry = get_fully_connected_layer_entry(ptr);
    
//     if (input->in_size_ != entry->base.in_size_)
//     {
//         printf("Error input size not match %lu/%lu\n", input->in_size_, entry->base.in_size_);
//         exit(-1);
//     }
//     float_t *in = input->in_ptr_;
//     float_t *a = entry->base.a_ptr_; // 中間結果緩衝區
//     float_t *W = entry->base._W;     // 權重矩陣
//     float_t *b = entry->base._b;     // 偏置向量
//     float_t *out = entry->base.out_ptr_; // 輸出緩衝區
//     input->in_ptr_ = out;
//     input->in_size_ = entry->base.out_size_;

//     uint32_t total_size = entry->base.out_size_;
//     uint32_t in_size = entry->base.in_size_;
//     // for(int i = 0 ; i < in_size ; i ++){
//     //     printf("in[%d] = %f\n",i,in[i]);
//     // }
    
//     // 遍歷每個輸出節點
//     for (int i = 0; i < total_size; i++)
//     {
//         // 1. 設置目標數量
//         volatile uint32_t *target_num_reg = (uint32_t *)0xC4020000;
//         *target_num_reg = in_size;
        
//         // 2. 寫入緩衝區 A 和 B
//         for (uint32_t c = 0; c < in_size; c++)
//         {
//             volatile uint32_t *buffer_a = (uint32_t *)(0xC4000000 + c * 4);
//             volatile uint32_t *buffer_b = (uint32_t *)(0xC4010000 + c * 4);
//             // printf("(buf_load: %d, %f, %f)\n", (int)c, W[i * in_size + c], in[c]);
//             *buffer_a = *(uint32_t *)&W[i * in_size + c]; // 權重轉換為 uint32_t
//             *buffer_b = *(uint32_t *)&in[c];              // 輸入轉換為 uint32_t
//         } 
        
//         // 3. 等待硬體完成計算
//         volatile uint32_t *result_reg = (uint32_t *)0xC4030000;
//         // while (!(*(volatile uint32_t *)result_reg)) {} // 忙等待

//         // 4. 讀取硬體結果
//         // a[i] += *(float_t *)result_reg;
//         a[i] = *(float_t *)result_reg;

//         // 5. 加入偏置（若有）
//         if (entry->has_bias_)
//             a[i] += b[i];
//         // printf("a[%d]=%f\n", i, a[i]);
//     }

//     // 應用激活函數
//     for (uint64_t i = 0; i < total_size; i++)
//     {
//         out[i] = entry->base.activate(a, i, entry->base.out_size_);
//     }

// #ifdef PRINT_LAYER
//     printf("[%s] done [%f, %f, ... , %f, %f]\n", entry->base.layer_name_, out[0], out[1], out[entry->base.out_size_-2], out[entry->base.out_size_-1]);
// #endif
// }

void fully_connected_layer_forward_propagation(struct list_node *ptr, input_struct *input)
{
    //printf("call_func1 ");
    fully_connected_layer *entry = get_fully_connected_layer_entry(ptr);
    
    if (input->in_size_ != entry->base.in_size_)
    {
        printf("Error input size not match %lu/%lu\n", input->in_size_, entry->base.in_size_);
        exit(-1);
    }
    float_t *in = input->in_ptr_;
    float_t *a = entry->base.a_ptr_; // 中間結果緩衝區
    // float_t *W = entry->base._W;     // 權重矩陣
    float_t *b = entry->base._b;     // 偏置向量
    float_t *out = entry->base.out_ptr_; // 輸出緩衝區
    input->in_ptr_ = out;
    input->in_size_ = entry->base.out_size_;

    uint32_t total_size = entry->base.out_size_;
    uint32_t in_size = entry->base.in_size_;
    // for(int i = 0 ; i < in_size ; i ++){
    //     printf("in[%d] = %f\n",i,in[i]);
    // }
    
    // 遍歷每個輸出節點
    for (int i = 0; i < total_size; i++)
    {
        // 1. 設置目標數量
        volatile uint32_t *target_num_reg = (uint32_t *)0xC4030000;
        *target_num_reg = i;
        
        // 2. 寫入緩衝區 A 和 B
        for (uint32_t c = 0; c < in_size; c++){
            volatile uint32_t *buffer_b = (uint32_t *)(0xC4020000 + c * 4);
            *buffer_b = *(uint32_t *)&in[c];
        } 
        
        // 3. 等待硬體完成計算
        volatile float_t *result_reg = (float_t *)0xC4030004;
        // while (!(*(volatile uint32_t *)result_reg)) {} // 忙等待

        // 4. 讀取硬體結果
        // a[i] += *(float_t *)result_reg;
        a[i] = *result_reg;

        // 5. 加入偏置（若有）
        if (entry->has_bias_){
            a[i] += b[i];
            //printf("aaa");
        }
            
        //printf("a[%d]=%f\n", i, b[i]);
    }

    // 應用激活函數
    for (uint64_t i = 0; i < total_size; i++)
    {
        out[i] = entry->base.activate(a, i, entry->base.out_size_);
    }

#ifdef PRINT_LAYER
    printf("[%s] done [%f, %f, ... , %f, %f]\n", entry->base.layer_name_, out[0], out[1], out[entry->base.out_size_-2], out[entry->base.out_size_-1]);
#endif
}

layer_base * new_fully_connected_layer(
                                       cnn_controller *ctrl,
                                       float_t(*activate) (float_t *, uint64_t, uint64_t),
                                       uint64_t in_dim,
                                       uint64_t out_dim,
                                       uint8_t has_bias
                                       )
{
    fully_connected_layer *ret = (fully_connected_layer *)malloc(sizeof(fully_connected_layer));

    ctrl->padding_size = 0;
    init_layer(&ret->base,
               ctrl,
               in_dim,
               out_dim,
               in_dim * out_dim,
               has_bias ? out_dim : 0,
               activate==relu);
#ifdef PRINT_LAYER
    static uint64_t call_time = 0;
    sprintf(ret->base.layer_name_, "fc%lu", call_time++);
#endif
    ret->has_bias_ = has_bias;
    ret->base.activate = activate;
    // printf("insize of FC layer %d\n", ret->base.in_size_);
    // printf("FC: in [%f, %f, ... , %f, %f]\n", ret->base.in_ptr_[0], ret->base.in_ptr_[1], ret->base.in_ptr_[ret->base.in_size_-2], ret->base.in_ptr_[ret->base.in_size_-1]);
#ifdef PRINT_LAYER
    printf("FC: W  [%f, %f, ... , %f, %f]\n", ret->base._W[0], ret->base._W[1], ret->base._W[in_dim * out_dim-2], ret->base._W[in_dim * out_dim-1]);
#endif
    // printf("FC: b  [%f, %f, ... , %f, %f]\n", ret->base._b[0], ret->base._b[1], ret->base._b[out_dim-2], ret->base._b[out_dim-1]);
    ret->base.forward_propagation = fully_connected_layer_forward_propagation;
    return &ret->base;
}
