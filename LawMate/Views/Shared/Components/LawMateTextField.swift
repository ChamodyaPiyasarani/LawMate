//
//  LawMateTextField.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Reusable rounded input field with SF Symbol leading icon.
//  Supports plain text and secure (password) mode.
//

import SwiftUI

struct LawMateTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    @State private var isPasswordVisible: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.lmTextSecondary)
                .frame(width: 20)

            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .font(.lmField)
                    .foregroundColor(.lmTextPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text)
                    .font(.lmField)
                    .foregroundColor(.lmTextPrimary)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 13))
                        .foregroundColor(.lmTextSecondary)
                        .frame(width: 15)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 100, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(placeholder)
        .accessibilityValue(isSecure && !text.isEmpty ? "Secured" : text)
    }
}

#Preview {
    VStack(spacing: 16) {
        LawMateTextField(icon: "person",     placeholder: "User Name",     text: .constant(""))
        LawMateTextField(icon: "at",         placeholder: "Email Address", text: .constant(""))
        LawMateTextField(icon: "phone",      placeholder: "Contact Number",text: .constant(""), keyboardType: .phonePad)
        LawMateTextField(icon: "lock",       placeholder: "Password",      text: .constant(""), isSecure: true)
    }
    .padding()
    .background(Color.lmBackground)
}
