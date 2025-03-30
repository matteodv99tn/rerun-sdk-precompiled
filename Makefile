RERUN_VERSION_MAJOR = 20
RERUN_VERSION_MINOR = 3
RERUN_VERSION = 0.$(RERUN_VERSION_MAJOR).$(RERUN_VERSION_MINOR)
ZIP_FILE = rerun_cpp_sdk.zip
TAR_FILE = rerun_cpp_sdk-$(RERUN_VERSION).tar.gz
DEB_FILE = rerun-cpp-sdk_0.$(RERUN_VERSION_MAJOR)_$(RERUN_VERSION_MINOR)
SRC_DIR = ./src
BUILD_DIR = ./build
DEB_BUILD_DIR = ./deb-build
BUILD_TIMESTAMP = $(BUILD_DIR)/build_complete
INSTALL_DIR = ./install

.PHONY: all tarball clean debian deb

all: $(TAR_FILE) $(DEB_FILE)

tarball: $(TAR_FILE)

debian: $(DEB_FILE)

deb: $(DEB_FILE)

clean:
	rm $(TAR_FILE) $(BUILD_DIR) $(INSTALL_DIR) $(DEB_BUILD_DIR) $(DEB_FILE) -rf 

$(ZIP_FILE):
	@echo "Retrieving $(ZIP_FILE), version $(RERUN_VERSION), from GitHub"
	@curl -OL https://github.com/rerun-io/rerun/releases/download/$(RERUN_VERSION)/rerun_cpp_sdk.zip 

$(SRC_DIR): $(ZIP_FILE)
	@echo "Unzipping content of $(ZIP_FILE) into $(SRC_DIR)"
	@unzip $(ZIP_FILE) -d $(SRC_DIR)
	@mv $(SRC_DIR)/rerun_cpp_sdk/* $(SRC_DIR)

$(BUILD_DIR): $(SRC_DIR)
	@echo "Configuring CMake build into $(BUILD_DIR)"
	@cmake -S $(SRC_DIR) -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR)

$(BUILD_TIMESTAMP):  $(BUILD_DIR)
	@echo "Building the project"
	@cmake --build $(BUILD_DIR) --parallel
	@touch $(BUILD_TIMESTAMP)

$(INSTALL_DIR): $(BUILD_TIMESTAMP)
	@echo "Installing the project into $(INSTALL_DIR)"
	@cmake --install $(BUILD_DIR) --prefix $(INSTALL_DIR)


$(TAR_FILE): $(INSTALL_DIR)
	@echo "Creating tarball object $(TAR_FILE)"
	@tar -cvzf $(TAR_FILE) -C $(INSTALL_DIR) .

$(DEB_BUILD_DIR): $(INSTALL_DIR) control.template
	@echo "Setting up debian packaging into $(DEB_BUILD_DIR)"
	@mkdir -p $(DEB_BUILD_DIR)
	@cp -r $(INSTALL_DIR)/* $(DEB_BUILD_DIR)
	@mkdir -p $(DEB_BUILD_DIR)/DEBIAN $(DEB_BUILD_DIR)/usr
	@mv $(DEB_BUILD_DIR)/include $(DEB_BUILD_DIR)/usr
	@cp control.template $(DEB_BUILD_DIR)/DEBIAN/control

$(DEB_FILE): $(DEB_BUILD_DIR)
	@echo "Creating $(DEB_FILE) package"
	@dpkg-deb --build $(DEB_BUILD_DIR)
	@mv $(DEB_BUILD_DIR).deb $(DEB_FILE).deb
