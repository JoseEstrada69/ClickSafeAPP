//
//  ProfileView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct ProfileView: View {
    private enum LogoutOption: String, Identifiable {
        case currentDevice
        case allDevices

        var id: String { rawValue }
    }

    let user: Me
    let isLoggingOut: Bool
    let onMyReports: () -> Void
    let onEditName: () -> Void
    let onChangePassword: () -> Void
    let onLogout: (Bool) -> Void

    @State private var logoutOption: LogoutOption?
    @State private var showsPrivacyNotice = false

    private var initials: String {
        user.nombre
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }

    private var membershipText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMMM yyyy"

        return "Miembro desde \(formatter.string(from: user.fechaRegistro))"
    }

    private var versionText: String {
        guard let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String,
              !version.isEmpty else {
            return "Versión no disponible"
        }

        return "Versión \(version)"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: Theme.Spacing.withinCard) {
                    Text(verbatim: initials)
                        .font(.title.bold())
                        .foregroundStyle(Color.csOnNavy)
                        .padding(Theme.Spacing.screenMargin)
                        .background(Color.csNavy, in: Circle())
                        .accessibilityHidden(true)

                    Text(verbatim: user.nombre)
                        .font(.title2.bold())
                        .foregroundStyle(Color.csTextPrimary)

                    Text(verbatim: user.correo)
                        .font(.body)
                        .foregroundStyle(Color.csTextSecondary)

                    Text(verbatim: membershipText)
                        .font(.footnote)
                        .foregroundStyle(Color.csTextSecondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.withinCard)
            }
            .listRowBackground(Color.csSurface)

            Section {
                Button(action: onMyReports) {
                    Text(verbatim: "Mis reportes")
                        .frame(
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                }
            } header: {
                Text(verbatim: "Mi actividad")
            }
            .foregroundStyle(Color.csNavy)
            .listRowBackground(Color.csSurface)

            Section {
                Button(action: onEditName) {
                    Text(verbatim: "Editar nombre")
                        .frame(
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                }

                Button(action: onChangePassword) {
                    Text(verbatim: "Cambiar contraseña")
                        .frame(
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                }
            } header: {
                Text(verbatim: "Cuenta")
            }
            .foregroundStyle(Color.csNavy)
            .listRowBackground(Color.csSurface)

            Section {
                Button(role: .destructive) {
                    logoutOption = .currentDevice
                } label: {
                    Text(verbatim: "Cerrar sesión")
                        .frame(
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                }

                Button(role: .destructive) {
                    logoutOption = .allDevices
                } label: {
                    Text(
                        verbatim:
                            "Cerrar sesión en todos los dispositivos"
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(
                        minHeight: Theme.Size.minimumTouchTarget
                    )
                }

                if isLoggingOut {
                    HStack {
                        ProgressView()
                            .accessibilityHidden(true)

                        Text(verbatim: "Cerrando sesión…")
                            .font(.body)
                    }
                }
            } header: {
                Text(verbatim: "Sesión")
            } footer: {
                VStack(spacing: Theme.Spacing.withinCard) {
                    Text(verbatim: versionText)
                        .font(.footnote)
                        .foregroundStyle(Color.csTextSecondary)

                    Button {
                        showsPrivacyNotice = true
                    } label: {
                        Text(verbatim: "Aviso de privacidad")
                            .font(.footnote)
                            .underline()
                            .foregroundStyle(Color.csNavy)
                            .frame(
                                minHeight:
                                    Theme.Size.minimumTouchTarget
                            )
                    }
                    .buttonStyle(.plain)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.withinCard)
            }
            .listRowBackground(Color.csSurface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Perfil"))
        .disabled(isLoggingOut)
        .sheet(isPresented: $showsPrivacyNotice) {
            PrivacyNoticeView()
        }
        .alert(item: $logoutOption) { option in
            Alert(
                title: Text(
                    verbatim: option == .allDevices
                        ? "¿Cerrar sesión en todos los dispositivos?"
                        : "¿Cerrar sesión?"
                ),
                message: Text(
                    verbatim:
                        "Necesitarás iniciar sesión para volver a entrar."
                ),
                primaryButton: .destructive(
                    Text(verbatim: "Cerrar sesión")
                ) {
                    onLogout(option == .allDevices)
                },
                secondaryButton: .cancel(
                    Text(verbatim: "Cancelar")
                )
            )
        }
    }
}

private struct PrivacyNoticeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.betweenBlocks
                ) {
                    noticeSection(
                        title: "Datos de tu cuenta",
                        message:
                            "ClickSafe utiliza tu nombre, correo electrónico y fecha de registro para identificar tu cuenta y mostrar tu perfil."
                    )

                    noticeSection(
                        title: "Reportes y comentarios",
                        message:
                            "Los reportes incluyen el título, la descripción, el enlace de la publicación, la plataforma y el tipo de fraude. También se utilizan los comentarios y las interacciones con los reportes para ofrecer las funciones de la comunidad."
                    )

                    noticeSection(
                        title: "Evidencias públicas",
                        message:
                            "Las imágenes que adjuntes a un reporte son públicas y pueden ser vistas por la comunidad. Antes de enviarlas, evita incluir contraseñas, documentos de identidad, datos bancarios u otra información personal que no quieras compartir."
                    )

                    noticeSection(
                        title: "Publicación anónima",
                        message:
                            "Publicar anónimamente oculta tu identidad en la publicación visible para la comunidad. No significa que la publicación deje de estar asociada a tu cuenta."
                    )

                    noticeSection(
                        title: "Sesión en el dispositivo",
                        message:
                            "La app utiliza credenciales de sesión para mantener tu acceso. El token de acceso se conserva en memoria y el token de renovación se guarda en el almacenamiento seguro del dispositivo."
                    )
                }
                .padding(Theme.Spacing.screenMargin)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.csBackground.ignoresSafeArea())
            .navigationTitle(Text(verbatim: "Aviso de privacidad"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(verbatim: "Cerrar")
                    }
                }
            }
        }
        .tint(Color.csNavy)
    }

    private func noticeSection(
        title: String,
        message: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            Text(verbatim: title)
                .font(.headline)
                .foregroundStyle(Color.csTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(verbatim: message)
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
