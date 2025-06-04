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
            let _ = print("Geo=\(geometry.size)")
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
                        height: containerHeight/3
                    )
                    
                    windowPosition = CGPoint(
                        x: 100+windowSize.width/2, // containerWidth - (windowSize.width / 2),
                        y: 100+windowSize.height/2 // containerHeight / 2
                    )
                    
                    hasInitialized = true
                }
            }
        }
        //.padding()
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
    let minSize: CGSize = .init(width: 200, height: 200)
    
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            content()
                .frame(width: size.width + resizeDelta.width,
                       height: size.height - 44 + resizeDelta.height)
        }
        .overlay(
            ResizeHandle(
                size: $size,
                resizeDelta: $resizeDelta,
                position: $position,
                containerSize: containerSize
            )
        )
        
        .frame(width: size.width + resizeDelta.width,
               height: size.height + resizeDelta.height)
        .background(Material.ultraThin)
        .cornerRadius(12)
        .shadow(radius: 10)
        .position(
            x: position.x + dragOffset.width + resizeDelta.width/2,
            y: position.y + dragOffset.height + resizeDelta.height/2)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isResizing, !isDragging {
                        let y = value.startLocation.y - (position.y - size.height/2)
                        if y > 0, y < 44 {
                            isDragging = true
                        } else if y > size.height-44 {
                            isResizing = true
                        }
                    }
                    
                    if isDragging {
                        dragOffset = value.translation
                    } else if isResizing {
                        let proposedWidth = size.width + value.translation.width
                        let proposedHeight = size.height + value.translation.height
                        
                        resizeDelta = CGSize(
                            width: max(minSize.width, proposedWidth) - size.width,
                            height: max(minSize.height, proposedHeight) - size.height)
                    }
                }
                .onEnded { value in
                    if isDragging {
                        let newX = position.x + dragOffset.width
                        let newY = position.y + dragOffset.height
                        
                        position.x = max(size.width/2, min(newX, containerSize.width-size.width/2))
                        position.y = max(size.height/2, min(newY, containerSize.height-size.height/2))
                        dragOffset = .zero
                        isDragging = false
                    } else if isResizing {
                        position.x += resizeDelta.width/2
                        position.y += resizeDelta.height/2
                        size.width += resizeDelta.width
                        size.height += resizeDelta.height

                        resizeDelta = .zero
                        isResizing = false
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
        .background(isDragging ? Material.thickMaterial : Material.regular)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))
    }
}

struct ResizeHandle: View {
    @Binding var size: CGSize
    @Binding var resizeDelta: CGSize
    @Binding var position: CGPoint
    let containerSize: CGSize
    let roundSizeRegion = 44.0
    
    var body: some View {
        Canvas { context, size in
            let radius = 10.0
            let center = CGPoint(x: 31, y: 31)
            let startAngle = Angle.degrees(0)
            let endAngle = Angle.degrees(90)
            
            var path = Path()
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            
            context.stroke(
                path,
                with: resizeDelta != .zero ? .color(.white) : .color(.secondary),
                style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .frame(width: roundSizeRegion, height: roundSizeRegion)
        .cornerRadius(4)
        .position(x: size.width - roundSizeRegion/2 + resizeDelta.width,
                  y: size.height - roundSizeRegion/2 + resizeDelta.height)
    }
}

#Preview {
    ContentView()
}
