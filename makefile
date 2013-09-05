JRUBYC = jrubyc

BUILD_DIR = build

SRC_DIRS = . lib console robot robot/behaviors robot/robot_interfaces
BUILD_DIRS = $(addprefix $(BUILD_DIR)/,$(SRC_DIRS))

SRCS = $(foreach sdir,$(SRC_DIRS),$(wildcard $(sdir)/*.rb))
CLASSES = $(patsubst %.rb,$(BUILD_DIR)/%.class,$(SRCS))

vpath %.rb $(SRC_DIRS)

define make-goal
$1/%.class: %.rb
	$(JRUBYC) -t $(BUILD_DIR) $$<
endef

all: checkdirs $(CLASSES)

checkdirs: $(BUILD_DIRS)

$(BUILD_DIRS):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR)

clean2:
	@find . -name \*.class -type f -exec rm -f {} +

$(foreach bdir,$(BUILD_DIRS),$(eval $(call make-goal,$(bdir))))
