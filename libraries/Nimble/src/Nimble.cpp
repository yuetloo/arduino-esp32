// Copyright 2015-2016 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "sdkconfig.h"
#include "esp32-hal-log.h"
#include "esp32-hal-bt.h"
#include "esp_nimble_hci.h"
#include "services/gap/ble_svc_gap.h"
#include "store/config/ble_store_config.h"
#include "nimble/nimble_port.h"
#include "services/gatt/ble_svc_gatt.h"
#include "host/ble_hs.h"
#include "nimble/nimble_port_freertos.h"
#include "Nimble.h"


Nimble::Nimble()
{
    m_deviceName = "nimble";
}

Nimble::~Nimble(void)
{
}

String Nimble::getDeviceName()
{
   return m_deviceName;
}

bool Nimble::init(String deviceName) 
{
    if (deviceName.length())
    {
        m_deviceName = deviceName;
    }

    //this line is needed to force link with esp32-hal-bt.c
    // so that btIsInuse() in esp32-hal-misc.c will be
    // overwritten with that in esp32-hal-bt.c, which will
    // return true and make sure initArduino() will not
    // release all bt controller memory causing the following
    // controller init call to fail with 'invalid state' (256) error
    assert(btStarted() == false);

    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ret = esp_nimble_hci_and_controller_init();
    if (ret != ESP_OK)
    {
        return false;
    }

    nimble_port_init();

    ret = ble_svc_gap_device_name_set(m_deviceName.c_str());
    if (ret != ESP_OK)
    {
        return false;
    }

    ble_store_config_init();



    return true;
}

esp_err_t Nimble::addService(const struct ble_gatt_svc_def *svcs)
{
    ble_svc_gap_init();
    ble_svc_gatt_init();
    esp_err_t ret = ble_gatts_count_cfg(svcs);
    if (ret != 0)
    {
        return ret;
    }

    ret = ble_gatts_add_svcs(svcs);
    return ret;
}

void Nimble::setResetCallback(ble_hs_reset_fn *pResetCb) 
{
   ble_hs_cfg.reset_cb = pResetCb;
}

void Nimble::setSyncCallback(ble_hs_sync_fn  *pSyncCb)
{
   ble_hs_cfg.sync_cb = pSyncCb;
}

void Nimble::setGattRegisterCallback(ble_gatt_register_fn *pRegCb)
{
   ble_hs_cfg.gatts_register_cb = pRegCb;
}

void Nimble::setStoreStatusCallback(ble_store_status_fn *pStoreCb)
{
   ble_hs_cfg.store_status_cb = pStoreCb;   
}

void Nimble::setSmIoCap(uint8_t sm_io_cap)
{
   ble_hs_cfg.sm_io_cap = sm_io_cap;
}

void Nimble::setSecureConnectionFlag(unsigned flag)
{
   ble_hs_cfg.sm_sc = flag;
}

void Nimble::start(TaskFunction_t task)
{
   nimble_port_freertos_init(task);
}

void Nimble::end()
{
}
