//
//  NotificationsScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 09/10/26.
//

import SwiftUI

@MainActor
struct NotificationsScreen: View {
    private struct ReportDestination: Hashable, Identifiable {
        let id: Int
    }

    private let api: any APIClient
    private let unreadModel: UnreadNotificationsViewModel

    @State private var model: NotificationsViewModel
    @State private var pendingNotificationID: Int?
    @State private var selectedReport: ReportDestination?
    @State private var retryRequested = false
    @State private var markAllRequested = false

    init(
        api: any APIClient,
        unreadModel: UnreadNotificationsViewModel
    ) {
        self.api = api
        self.unreadModel = unreadModel

        _model = State(
            initialValue: NotificationsViewModel(api: api)
        )
    }

    private var isBusy: Bool {
        model.isBusy
            || pendingNotificationID != nil
            || markAllRequested
            || retryRequested
    }

    var body: some View {
        List {
            if !model.hasLoaded, model.errorMessage == nil {
                loadingRow("Cargando notificaciones")
            }

            if model.hasLoaded, model.notifications.isEmpty {
                EmptyStateView(
                    symbol: "bell.slash",
                    title: "No tienes notificaciones",
                    message: "Las novedades de tus reportes aparecerán aquí."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(model.notifications) { notification in
                Button {
                    guard !isBusy else { return }
                    pendingNotificationID = notification.id
                } label: {
                    notificationRow(notification)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityHint(
                    Text(
                        verbatim:
                            "Marcar como leída y abrir el reporte"
                    )
                )
            }

            if let message = model.actionErrorMessage {
                Text(verbatim: message)
                    .font(.body)
                    .foregroundStyle(Color.csDanger)
                    .fixedSize(horizontal: false, vertical: true)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if let message = model.errorMessage {
                ErrorBanner(message: message) {
                    retryRequested = true
                }
                .disabled(isBusy)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if model.hasLoaded,
               model.hasMore,
               model.errorMessage == nil {
                loadingRow("Cargando más notificaciones")
                    .task(id: model.notifications.count) {
                        await model.loadMore()
                    }
            } else if model.hasLoaded, model.isLoading {
                loadingRow("Actualizando notificaciones")
            }

            if model.isMarkingRead {
                loadingRow("Actualizando estado de lectura")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Notificaciones"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.csNavy)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard !isBusy else { return }
                    markAllRequested = true
                } label: {
                    Text(verbatim: "Marcar todas como leídas")
                }
                .disabled(
                    isBusy
                        || !model.hasLoaded
                        || (
                            !model.hasUnreadNotifications
                                && unreadModel.count == 0
                        )
                )
            }
        }
        .navigationDestination(item: $selectedReport) {
            destination in

            ReportDetailScreen(
                reportID: destination.id,
                api: api
            )
        }
        .task {
            async let notifications: Void = loadNotifications()
            async let count: Void = unreadModel.refresh()
            _ = await (notifications, count)
        }
        .refreshable {
            async let notifications: Void = model.refresh()
            async let count: Void = unreadModel.refresh()
            _ = await (notifications, count)
        }
        .task(id: pendingNotificationID) {
            guard let id = pendingNotificationID,
                  let notification = model.notifications.first(
                    where: { $0.id == id }
                  ) else {
                return
            }

            let markedRead = await model.markRead(notification)

            guard !Task.isCancelled else { return }

            if markedRead {
                await unreadModel.refresh()

                guard !Task.isCancelled else { return }

                selectedReport = ReportDestination(
                    id: notification.reporteId
                )
            }

            pendingNotificationID = nil
        }
        .task(id: markAllRequested) {
            guard markAllRequested else { return }

            let markedRead = await model.markAllRead()

            guard !Task.isCancelled else { return }

            if markedRead {
                await unreadModel.refresh()
            }

            guard !Task.isCancelled else { return }
            markAllRequested = false
        }
        .task(id: retryRequested) {
            guard retryRequested else { return }

            await model.retry()

            guard !Task.isCancelled else { return }
            retryRequested = false
        }
        .onDisappear {
            pendingNotificationID = nil
            retryRequested = false
            markAllRequested = false
        }
    }

    private func notificationRow(
        _ notification: AppNotification
    ) -> some View {
        let appearance = appearance(for: notification.tipo)

        return CSCard {
            HStack(
                alignment: .top,
                spacing: Theme.Spacing.withinCard
            ) {
                Image(systemName: appearance.symbol)
                    .font(.title2)
                    .foregroundStyle(appearance.color)
                    .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.withinCard
                ) {
                    Text(verbatim: notification.mensaje)
                        .font(
                            .body.weight(
                                notification.leida ? .regular : .bold
                            )
                        )
                        .foregroundStyle(Color.csTextPrimary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    Text(
                        notification.fechaCreacion,
                        format: .dateTime
                            .day()
                            .month()
                            .year()
                            .hour()
                            .minute()
                            .locale(Locale(identifier: "es_MX"))
                    )
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !notification.leida {
                    Circle()
                        .fill(Color.csGold)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.csTextSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Theme.Size.minimumTouchTarget)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            Text(
                verbatim: notification.leida
                    ? "Leída"
                    : "No leída"
            )
        )
    }

    private func appearance(
        for type: String
    ) -> (symbol: String, color: Color) {
        switch type {
        case "reporte_validado":
            return (
                "exclamationmark.shield.fill",
                .csValidatedFg
            )

        case "reporte_rechazado":
            return ("xmark.shield", .csRejectedFg)

        case "nuevo_comentario":
            return ("bubble.left", .csBlue)

        case "comentario_ocultado":
            return ("eye.slash", .csTextSecondary)

        default:
            return ("bell", .csTextSecondary)
        }
    }

    private func loadNotifications() async {
        if model.hasLoaded {
            await model.refresh()
        } else {
            await model.loadInitial()
        }
    }

    private func loadingRow(_ title: String) -> some View {
        HStack {
            Spacer()

            ProgressView()
                .accessibilityLabel(Text(verbatim: title))

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.withinCard)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
