//
//  main.swift
//  
//
//  Created by Emory Dunn on 5/20/21.
//

import Foundation
import RoomOccupancyKit


let manager = SensorManager(
    sensors: [
        Sensor(URL(string: "http://10.0.2.163/raw")!,
               topName: .room("Hall"),
               bottomName: .room("Office"))
//        Sensor(URL(string: "http://10.0.2.163/raw")!,
//               topName: .æther,
//               bottomName: .room("Office"))
    ],
    haConfig: HAConfig(
        url: URL(string: "http://10.0.1.58:8123")!,
        token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJkMDA0YmY0ODAxMTM0N2QzYmU4YTk3OWRmNDI0NjYwNSIsImlhdCI6MTYyMTM2NTg3NiwiZXhwIjoxOTM2NzI1ODc2fQ.npYPDmQFQNQ3GFSJS6DfdM5GWD6GVfaAaWnW-9yixWw")
)

//let running = DispatchSemaphore(value: 0)

manager.monitorSensors()
RunLoop.main.run()

//running.wait()
