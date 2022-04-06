TARGET = app

DEBUG = 1
# optimization
OPT = -O3 -g

$(shell python preBuild.py)
VERSION = $(shell python getVersion.py)_$(shell git rev-parse --short HEAD)

# Build path
BUILD_DIR = build

# sdk path
SDK_DIR = sdk


# 系统平台
ifeq ($(OS),Windows_NT)
	PLATFORM="Windows"
else
	ifeq ($(shell uname),Darwin)
  		PLATFORM="MacOS"
 	else
  		PLATFORM="Unix-Like"
 	endif
endif

$(info PLATFORM: $(PLATFORM))


######################################
# source
######################################
# C sources
C_SOURCES =  \
Src/main.c \
Src/delay.c \
Src/hk32f0xx_it.c  \
Src/led.c  \
$(SDK_DIR)/platform/hk/HK32F030/STD_LIB/src/hk32f0xx_gpio.c	\
$(SDK_DIR)/platform/hk/HK32F030/STD_LIB/src/hk32f0xx_misc.c	\
$(SDK_DIR)/platform/hk/HK32F030/STD_LIB/src/hk32f0xx_rcc.c	\
$(SDK_DIR)/platform/hk/HK32F030/CMSIS/CM0/DeviceSupport/system_hk32f0xx.c

# C includes
C_INCLUDES =  \
-ISrc \
-I$(SDK_DIR)/platform/hk/HK32F030/STD_LIB/inc \
-I$(SDK_DIR)/platform/hk/HK32F030/CMSIS/CM0/DeviceSupport \
-I$(SDK_DIR)/platform/hk/HK32F030/CMSIS/CM0/CoreSupport

# ASM sources
ASM_SOURCES =  \
startup_hk32f030x8_gcc.s



#######################################
# binaries
#######################################
# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.

PREFIX = arm-none-eabi-
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif

HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

# CC = armcc
# AS = armasm
# LD = armlink
# AR = armar


# LOG Message
$(info VERSION: $(VERSION))
$(info sdk path: $(SDK_DIR))


#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m0

# fpu
# NONE for Cortex-M0/M0+/M3

# float-abi


# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

# macros for gcc
# AS defines
AS_DEFS = 

# C 宏
C_DEFS =  \
-DUSE_STDPERIPH_DRIVER \
-DHK32F030 \
-DVERSION="${VERSION}"



# AS includes
AS_INCLUDES = 


# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = STM32F030C8Tx_FLASH.ld

# libraries
LIBS = -lc -lm -lnosys 
LIBDIR = 
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin


#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir $@		

#######################################
# clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR)

#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)


include cmd.mk

# *** EOF ***