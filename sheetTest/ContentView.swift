//
//  ContentView.swift
//  sheetTest
//
//  Created by Miguel de Icaza on 6/1/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State var showConfiguration = false
    @State var showFloating = true
    // The position of the floating window
    @State var windowPosition: CGPoint = .zero
    // The size of the floating window
    @State var windowSize: CGSize = .zero
    @State var oldWindowSize: CGSize = .zero
    @State var text = ""
    @State private var hasInitialized = false
    @State var floatingRect: CGRect = .zero
    @State var keyboardFrame: CGRect = .zero
    
    var windowContent: some View {
        VStack(alignment: .leading) {
            Text("Welcome to Claude for Xogot")
            Spacer()
            TextField("Enter your question", text: $text)
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
            ZStack(alignment: .topLeading) {
                Color.yellow
                Color.blue
                    .position(x: 0, y: floatingRect.midY)
                    .frame(width: 100, height: floatingRect.height)
                Color.blue
                    .position(x: 300, y: keyboardFrame.midY-20)
                    .frame(width: 100, height: keyboardFrame.height)
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
                        debugFloatingFrame: $floatingRect,
                        debugKeyboardFrame: $keyboardFrame,
                        content: { windowContent }
                    )
                }
            }
            .coordinateSpace(.named("container"))
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

// Requires the container to have a .coordinateSpace(.named("container"))
struct FloatingWindow<Content: View>: View {
    let containerSize: CGSize
    @Binding var position: CGPoint
    @Binding var size: CGSize
    @Binding var isVisible: Bool
    @Binding var debugFloatingFrame: CGRect
    @Binding var debugKeyboardFrame: CGRect
    @State var keyboardHeight: CGFloat = 0
    let content: () -> Content
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var resizeOffset = CGSize.zero
    @State var resizeDelta = CGSize.zero
    let minSize: CGSize = .init(width: 200, height: 200)
    
    /// Our canvas size in screen coordinates, this is used only to avoid the keyboard if it shows up
    @State var floatingAbsoluteFrame: CGRect = .zero
    @State var keyboardAbsoluteFrame: CGRect = .zero

    private var adjustedYPosition: CGFloat {
        if keyboardAbsoluteFrame.height > 0, keyboardAbsoluteFrame.minY < floatingAbsoluteFrame.maxY {
            print("We have a problem, about \(floatingAbsoluteFrame.maxY-keyboardAbsoluteFrame.minY)")
        }
        return position.y
    }
    
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            content()
                .frame(width: max(minSize.width, size.width + resizeDelta.width),
                       height: max(minSize.height, size.height - 44 + resizeDelta.height))
        }
        .overlay(
            ResizeHandle(
                size: $size,
                resizeDelta: $resizeDelta,
                position: $position,
                containerSize: containerSize
            )
        )
        .onGeometryChange(for: CGRect.self) {
            return $0.frame(in: .global)
        } action: { newValue in
            floatingAbsoluteFrame = newValue
            debugFloatingFrame = newValue

        }
        .frame(width: size.width + resizeDelta.width,
               height: size.height + resizeDelta.height)
        .background(Material.ultraThin)
        .cornerRadius(12)
        .shadow(radius: 10)
        .position(
            x: position.x + dragOffset.width + resizeDelta.width/2,
            y: adjustedYPosition + dragOffset.height + resizeDelta.height/2)
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardAbsoluteFrame = keyboardFrame
                self.debugKeyboardFrame = keyboardFrame
                //if floatingAbsoluteFrame.minY
                
                oldPosition = position
                oldSize = size
                if keyboardAbsoluteFrame.height > 0, keyboardAbsoluteFrame.minY < floatingAbsoluteFrame.maxY {
                    withAnimation {
                        // Ok, this is sort of lame, it only pushes the window up the necessary space,
                        // it looks good, but is not perfect, there might not be enough space, so we need
                        // to also shrink if needed
                        position = CGPoint(x: position.x, y: position.y - (floatingAbsoluteFrame.maxY - keyboardAbsoluteFrame.minY))
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardAbsoluteFrame = .zero
            withAnimation {
                position = oldPosition
                size = oldSize
            }
        }
    }
    @State var oldPosition = CGPoint.zero
    @State var oldSize = CGSize.zero
    
    private var titleBar: some View {
        HStack {
            Menu {
                Button("aa") {}
            } label: {
                Image(systemName: "gear")
                    .font(.title2)
            }
            .foregroundStyle(.gray)
            Spacer()
            Text("Chat Window")
                .foregroundColor(.secondary)
            Spacer()

            Button(action: { isVisible = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
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
