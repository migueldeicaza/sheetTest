//
//  ContentView.swift
//  sheetTest
//
//  Created by Miguel de Icaza on 6/1/25.
//

import SwiftUI

struct ContentView: View {
    @State var showConfiguration = false
    @State var showFloating = true
    @State var windowPosition = CGPoint(x: 100, y: 100)
    @State var windowSize = CGSize(width: 300, height: 200)
    @State var text = ""
    
    var windowContent: some View {
        VStack {
            Text("This is the content for the window")
            TextField("DEmo", text: $text)
        }
        .padding()
        .background(Material.ultraThin)
    }
    var body: some View {
        ZStack {
            Color.yellow
            VStack {
                Button("Toggle Floating Window") {
                    showFloating.toggle()
                }
            }
            .sheet(isPresented: $showConfiguration) {
                Text("This code will display the Configuration View")
            }
            
            if showFloating {
                FloatingWindow(
                    position: $windowPosition,
                    size: $windowSize,
                    isVisible: $showFloating,
                    content: { windowContent }
                )
            }
        }
        .padding()
    }
}

struct FloatingWindow<Content: View>: View {
    @Binding var position: CGPoint
    @Binding var size: CGSize
    @Binding var isVisible: Bool
    let content: () -> Content
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var resizeOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            content()
                .frame(width: size.width, height: size.height - 30)
        }
        .frame(width: size.width, height: size.height)
        .background(Material.ultraThin)
        .cornerRadius(12)
        .shadow(radius: 10)
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isResizing {
                        isDragging = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { _ in
                    if isDragging {
                        position.x += dragOffset.width
                        position.y += dragOffset.height
                        dragOffset = .zero
                        isDragging = false
                    }
                }
        )
        .overlay(
            ResizeHandle(size: $size, isResizing: $isResizing)
                .position(x: size.width - 10, y: size.height - 10)
        )
    }
    
    private var titleBar: some View {
        HStack {
            Text("Floating Window")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("×") {
                isVisible = false
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: 30)
        .background(Material.regular)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
    }
}

struct ResizeHandle: View {
    @Binding var size: CGSize
    @Binding var isResizing: Bool
    @State private var resizeOffset = CGSize.zero
    
    var body: some View {
        Rectangle()
            .fill(Color.gray)
            .frame(width: 20, height: 20)
            .cornerRadius(4)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isResizing = true
                        resizeOffset = value.translation
                        size.width = max(200, size.width + value.translation.width - resizeOffset.width)
                        size.height = max(150, size.height + value.translation.height - resizeOffset.height)
                        resizeOffset = value.translation
                    }
                    .onEnded { _ in
                        isResizing = false
                        resizeOffset = .zero
                    }
            )
    }
}

#Preview {
    ContentView()
}
