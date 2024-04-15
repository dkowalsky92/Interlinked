//
//  ConfigurationView.swift
//  InterlinkedUI
//
//  Created by Dominik Kowalski on 23/05/2023.
//

import Foundation
import SwiftUI
import Combine

struct ConfigurationView: View {
    @ObservedObject private var viewModel: ConfigurationViewModel
    
    @FocusState var textFieldFocused: Bool
    
    init(viewModel: ConfigurationViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 12) {
                Text("Interlinked")
                    .foregroundColor(.secondary)
                    .font(.system(.body, weight: .regular))
                Divider()
                maxLineLengthView
                enableSortingView
                formatterStyleSelectionView(proxy: proxy)
                Divider()
                terminateView
            }
            .contentShape(Rectangle())
            .padding(12)
            .cornerRadius(10)
            .onTapGesture {
                textFieldFocused = false
            }
            .onAppear {
                textFieldFocused = false
                proxy.scrollTo(viewModel.formatterStyle.id, anchor: .center)
            }
        }
    }
    
    private var maxLineLengthView: some View {
        HStack(alignment: .center) {
            imageWithText(image: "ruler", title: "Maximum line length")
            
            Spacer()
            
            HStack(spacing: 0) {
                TextField(
                    "",
                    text: Binding(
                        get: {
                            String(viewModel.maxLineLength)
                        },
                        set: { newValue in
                            if let intValue = Int(newValue), viewModel.maxLineLengthRange.contains(intValue) {
                                viewModel.maxLineLength = intValue
                            }
                        }
                    )
                )
                .focused($textFieldFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .fixedSize()
                
                Stepper("", value: $viewModel.maxLineLength, in: viewModel.maxLineLengthRange)
                    .fixedSize()
            }
        }
    }
    
    private var enableSortingView: some View {
        switchRow(image: "arrow.up.and.down.text.horizontal", title: "Enable sorting", binding: $viewModel.enableSorting)
    }
    
    private func imageWithText(image: String, title: String) -> some View {
        HStack(spacing: 8) {
            Text(Image(systemName: image))
                .frame(width: 16)
            Text(title)
        }
        .font(Font.system(.body, weight: .regular))
        .foregroundColor(.primary)
    }
    
    private func switchRow(image: String, title: String, binding: Binding<Bool>) -> some View {
        HStack(alignment: .center) {
            imageWithText(image: image, title: title)
            
            Spacer()
            
            Toggle(isOn: binding, label: {})
                .foregroundColor(.accentColor)
                .toggleStyle(SwitchToggleStyle())
        }
    }
    
    private func formatterStyleSelectionView(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.formatterStyles) { item in
                    RoundedBorderTextView(
                        content: item.content,
                        description: item.description,
                        selected: Binding(
                            get: {
                                item == viewModel.formatterStyle
                            },
                            set: { _ in
                                viewModel.formatterStyle = item
                                withAnimation(.linear(duration: 0.2)) {
                                    proxy.scrollTo(item.id, anchor: .center)
                                }
                            }
                        )
                    )
                }
            }
            .padding(.horizontal, 175 / CGFloat(viewModel.formatterStyles.count))
        }
    }
    
    private var terminateView: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(Image(systemName: "power"))
            Text("Quit")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .font(Font.system(.body, weight: .regular))
        .foregroundColor(.primary)
        .onTapGesture {
            viewModel.terminate()
        }
    }
}
