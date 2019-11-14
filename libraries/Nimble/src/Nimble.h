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

#ifndef _NIMBLE_H_
#define _NIMBLE_H_

#include "sdkconfig.h"

#if defined(CONFIG_BT_ENABLED)

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "nimble/nimble_port_freertos.h"
#include "esp_bt.h"
#include "host/ble_hs.h"

#include "Arduino.h"

struct ble_gap_adv_params_s;

class Nimble
{
  public:
    Nimble(void);
    ~Nimble(void);

    /**
         * Initialize the Nimble host stack
         *
         * @param[in] localName  local name to advertise
         *
         * @return true on success
         *
         */
    bool init(String localName = String());
    esp_err_t addService(const struct ble_gatt_svc_def *svcs);
    String getDeviceName();
    void setResetCallback(ble_hs_reset_fn *pResetCb);
    void setSyncCallback(ble_hs_sync_fn  *pSyncCb);
    void setGattRegisterCallback(ble_gatt_register_fn *pRegCb);
    void setStoreStatusCallback(ble_store_status_fn *pStoreCb);
    void setSmIoCap(uint8_t sm_io_cap);
    void setSecureConnectionFlag(unsigned flag);
    void start(TaskFunction_t task);
    void end(void);

  private:
    String m_deviceName;

  private:
};

#endif

#endif
