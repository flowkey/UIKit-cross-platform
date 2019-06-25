//
//  TaskRegistry.swift
//  UIKit
//
//  Created by Chetan Agarwal on 24/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

extension URLSessionWrapperWithCustomURLCache {

    class TaskRegistry {

        private var registeredTasks = [Int: RegisteredTask]()

        func register(task: URLSessionTask,
                      onComplete completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
            let taskToRegister = RegisteredTask(task: task, completionHandler: completionHandler)
            registeredTasks[task.taskIdentifier] = taskToRegister
            print("added task \(task.taskIdentifier)")
        }

        func received(data: Data, for task: URLSessionTask) {
            guard let pendingTask = find(task: task) else  { return }
            if pendingTask.data == nil { pendingTask.data = Data() }
            pendingTask.data.append(data)
            print("received data for task \(task.taskIdentifier), \(data.count), total: \(pendingTask.data.count)")
        }

        func received(cachedResponse: CachedURLResponse, for task: URLSessionTask) {
            guard let pendingTask = find(task: task) else  { return }
            pendingTask.cachedResponse = cachedResponse
            print("received cached response for task \(task.taskIdentifier)")
        }

        func completeAndRemove(task: URLSessionTask, with response: URLResponse?, or error: Error?, saveToCache: (URLSessionTask, Data?) -> Void) {
            guard let pendingTask = find(task: task) else  { return }

            remove(task: task)

            guard let error = error else {
                pendingTask.completionHandler(pendingTask.data, response, nil)
                saveToCache(task, pendingTask.data)
                return
            }

            guard let cachedResponse = pendingTask.cachedResponse else {
                pendingTask.completionHandler(nil, response, error)
                return
            }
            pendingTask.completionHandler(cachedResponse.data, response, nil)
        }

        private func find(task: URLSessionTask) -> RegisteredTask? {
            let foundTask = registeredTasks[task.taskIdentifier]
            if foundTask == nil {
               assertionFailure("task not found \(task.taskIdentifier)")
            }
            return foundTask
        }

        private func remove(task: URLSessionTask) {
            registeredTasks[task.taskIdentifier] = nil
            print("removed task \(task.taskIdentifier), remaining \(registeredTasks.count)")
        }

        class RegisteredTask {
            var task: URLSessionTask
            var completionHandler: ((Data?, URLResponse?, Error?) -> Void)

            var data: Data!
            var cachedResponse: CachedURLResponse?

            init(task: URLSessionTask,
                 completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
                self.task = task
                self.completionHandler = completionHandler
            }
        }
    }
}
