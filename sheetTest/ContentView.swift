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
    @State var windowPosition: CGPoint = .zero
    @State var windowSize: CGSize = .zero
    @State var text = ""
    @State private var hasInitialized = false
    
    var windowContent: some View {
        VStack {
            Text("This is the content for the window")
            TextField("DEmo", text: $text)
        }
        .padding()
        .background(Material.ultraThin)
    }
    @State var showSheet = true
    var body3: some View {
        ZStack {
            Color.red
            Button("Toggle") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack {
                    Text("Very long long\nAnother line")
                        .padding()
                }.padding()
                    .presentationBackground(Material.regular)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large, .medium])
            }
        }
    }
    var body: some View {
        GeometryReader { geometry in
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
                        containerSize: geometry.size,
                        position: $windowPosition,
                        size: $windowSize,
                        isVisible: $showFloating,
                        content: { windowContent }
                    )
                }
            }
            .onAppear {
                if !hasInitialized {
                    let containerWidth = geometry.size.width
                    let containerHeight = geometry.size.height
                    
                    windowSize = CGSize(
                        width: containerWidth / 3,
                        height: containerHeight/1.2
                    )
                    
                    windowPosition = CGPoint(
                        x: containerWidth - (windowSize.width / 2),
                        y: containerHeight / 2
                    )
                    
                    hasInitialized = true
                }
            }
        }
        .padding()
    }
}

struct FloatingWindow<Content: View>: View {
    let containerSize: CGSize
    @Binding var position: CGPoint
    @Binding var size: CGSize
    @Binding var isVisible: Bool
    let content: () -> Content
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var resizeOffset = CGSize.zero
    @State var resizeDelta = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            content()
                .frame(width: size.width, height: size.height - 44)
        }
        .overlay(
            ResizeHandle(size: $size, resizeDelta: $resizeDelta, position: $position))
        
        .frame(width: size.width + resizeDelta.width, height: size.height + resizeDelta.height)
        .background(Material.ultraThin)
        .cornerRadius(12)
        .shadow(radius: 10)
        .position(
            x: position.x + dragOffset.width + resizeDelta.width/2,
            y: position.y + dragOffset.height + resizeDelta.height/2)
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
                        let newX = position.x + dragOffset.width
                        let newY = position.y + dragOffset.height
                        
                        position.x = max(size.width/2, min(newX, containerSize.width-size.width/2))
                        position.y = max(size.height/2, min(newY, containerSize.height-size.height/2))
                        dragOffset = .zero
                        isDragging = false
                    }
                }
        )
    }
    
    private var titleBar: some View {
        HStack {
            Menu {
                
            } label: {
                Text("xx")
            }
            Spacer()
            Text("Floating Window")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            
            Button(action: {
                // TODO
            }) {
                Text("New")
            }
            Button(action: { isVisible = false }) {
                Image(systemName: "xmark")
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .frame(height: 44)
        .background(Material.regular)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))
    }
}

struct ResizeHandle: View {
    @Binding var size: CGSize
    @Binding var resizeDelta: CGSize
    @Binding var position: CGPoint
    
    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 20, height: 20)
            .cornerRadius(4)
            .position(x: size.width - 10 + resizeDelta.width/2,
                      y: size.height - 10 + resizeDelta.height/2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        print("here \(value.translation)")
                        resizeDelta = value.translation
                    }
                    .onEnded { value in
                        position.x += value.translation.width/2
                        position.y += value.translation.height/2
                        resizeDelta = .zero
                        size.width += value.translation.width
                        size.height += value.translation.height
                    }
            )
    }
}

#Preview {
    ContentView()
}
