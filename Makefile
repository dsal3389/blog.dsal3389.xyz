
PROJECT_NAME=blog.dsal3389
SRC_PATH="./hugosrc/${PROJECT_NAME}"
OUTPUT_DIR="$$(pwd)/public"
HUGO_BUILD_FLAGS=--minify --gc


build:
	@hugo -D -s $(SRC_PATH) -d $(OUTPUT_DIR) $(HUGO_BUILD_FLAGS)

dev:
	@hugo -s $(SRC_PATH) server --watch=true --debug --ignoreCache

clean:
	@rm -rfv $(SRC_PATH)/public $(OUTPUT_DIR)
