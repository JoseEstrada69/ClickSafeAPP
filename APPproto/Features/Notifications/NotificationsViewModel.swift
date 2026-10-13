//
//  NotificationsViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 09/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotificationsViewModel {
    private(set) var notifications: [AppNotification] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var hasMore = false
    private(set) var isMarkingRead = false
    private(set) var errorMessage: String?
    private(set) var actionErrorMessage: String?

    var isBusy: Bool {
        isLoading || isMarkingRead
    }

    var hasUnreadNotifications: Bool {
        notifications.contains { !$0.leida }
    }

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private let pageSize = 20

    @ObservationIgnored
    private var nextPage = 1

    @ObservationIgnored
    private var failedRequestWasReset = true

    init(api: any APIClient) {
        self.api = api
    }

    func loadInitial() async {
        guard !hasLoaded else { return }
        await loadPage(reset: true)
    }

    func refresh() async {
        await loadPage(reset: true)
    }

    func loadMore() async {
        guard hasLoaded, hasMore, errorMessage == nil else {
            return
        }

        await loadPage(reset: false)
    }

    func retry() async {
        await loadPage(reset: failedRequestWasReset)
    }

    func markRead(_ notification: AppNotification) async -> Bool {
        guard !isBusy, !Task.isCancelled else {
            return false
        }

        guard notification.id > 0,
              notification.reporteId > 0 else {
            actionErrorMessage = "La notificación no es válida."
            return false
        }

        actionErrorMessage = nil

        if notification.leida {
            return true
        }

        isMarkingRead = true

        defer {
            isMarkingRead = false
        }

        do {
            try await api.sendWithoutResponse(
                Endpoint(
                    path: "notifications/\(notification.id)/read",
                    method: .patch
                )
            )

            try Task.checkCancellation()

            notifications = notifications.map {
                $0.id == notification.id
                    ? readCopy(of: $0)
                    : $0
            }

            return true
        } catch is CancellationError {
            return false
        } catch {
            actionErrorMessage = message(
                for: error,
                fallback: "No se pudo marcar la notificación como leída. Intenta de nuevo."
            )
            return false
        }
    }

    func markAllRead() async -> Bool {
        guard !isBusy, !Task.isCancelled else {
            return false
        }

        isMarkingRead = true
        actionErrorMessage = nil

        defer {
            isMarkingRead = false
        }

        do {
            try await api.sendWithoutResponse(
                Endpoint(
                    path: "notifications/read-all",
                    method: .patch
                )
            )

            try Task.checkCancellation()

            notifications = notifications.map {
                readCopy(of: $0)
            }

            return true
        } catch is CancellationError {
            return false
        } catch {
            actionErrorMessage = message(
                for: error,
                fallback: "No se pudieron marcar las notificaciones como leídas. Intenta de nuevo."
            )
            return false
        }
    }

    private func loadPage(reset: Bool) async {
        guard !isBusy, !Task.isCancelled else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let requestedPage = reset ? 1 : nextPage

        do {
            let response: Page<AppNotification> = try await api.send(
                Endpoint(
                    path: "notifications",
                    queryItems: [
                        URLQueryItem(
                            name: "page",
                            value: String(requestedPage)
                        ),
                        URLQueryItem(
                            name: "limit",
                            value: String(pageSize)
                        )
                    ]
                ),
                expecting: Page<AppNotification>.self
            )

            try Task.checkCancellation()

            let followingPage = requestedPage
                .addingReportingOverflow(1)
            let consumedItems = requestedPage
                .multipliedReportingOverflow(by: pageSize)

            guard response.page == requestedPage,
                  response.limit == pageSize,
                  response.total >= 0,
                  response.items.count <= pageSize,
                  !followingPage.overflow,
                  !consumedItems.overflow else {
                throw APIError.decoding
            }

            if reset {
                var seenIDs = Set<Int>()

                notifications = response.items.filter {
                    seenIDs.insert($0.id).inserted
                }

                actionErrorMessage = nil
            } else {
                var seenIDs = Set(notifications.map(\.id))

                notifications.append(
                    contentsOf: response.items.filter {
                        seenIDs.insert($0.id).inserted
                    }
                )
            }

            nextPage = followingPage.partialValue
            hasMore = !response.items.isEmpty
                && consumedItems.partialValue < response.total
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            failedRequestWasReset = reset
            errorMessage = message(
                for: error,
                fallback: "No se pudieron cargar las notificaciones. Intenta de nuevo."
            )
        }
    }

    private func readCopy(
        of notification: AppNotification
    ) -> AppNotification {
        AppNotification(
            id: notification.id,
            tipo: notification.tipo,
            mensaje: notification.mensaje,
            leida: true,
            reporteId: notification.reporteId,
            fechaCreacion: notification.fechaCreacion
        )
    }

    private func message(
        for error: Error,
        fallback: String
    ) -> String {
        guard let apiError = error as? APIError else {
            return fallback
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .notFound:
            return "La notificación ya no está disponible."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return fallback
        }
    }
}
