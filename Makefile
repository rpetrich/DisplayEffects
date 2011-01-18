TWEAK_NAME = DisplayEffects
DisplayEffects_OBJC_FILES = DisplayEffects.m
DisplayEffects_FRAMEWORKS = Foundation QuartzCore UIKit

ADDITIONAL_CFLAGS = -std=c99

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
