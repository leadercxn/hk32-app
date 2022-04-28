#ifndef __HK_PERIPHERAL_H
#define __HK_PERIPHERAL_H

#include "usart.h"
#include "gpio.h"
#include "systick.h"
#include "exit.h"

extern usart_object_t   g_usart_object;
extern gpio_object_t    g_led_obj;
extern systick_object_t g_systick_obj;
extern timer_object_t   g_timer3_object;
extern exit_object_t    g_exit4_15_obj;

#endif
