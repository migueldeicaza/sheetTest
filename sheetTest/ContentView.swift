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
            ZStack(alignment: .topLeading) {
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
                        title: "This is my Window",
                        containerSize: geometry.size,
                        position: $windowPosition,
                        size: $windowSize,
                        isVisible: $showFloating,
                        content: { windowContent },
                        menu: {
                            Menu {
                                Button("First Button") {}
                            } label: {
                                Image(systemName: "gear")
                                    .font(.title2)
                            }
                            .foregroundStyle(.gray)
                        }
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
struct FloatingWindow<Content: View, MenuContent: View>: View {
    let title: String
    // The size of the container where our floating window lives
    var containerSize: CGSize
    // the position of our window
    @Binding var position: CGPoint
    // the size of our window
    @Binding var size: CGSize
    // we use this to control on/off
    @Binding var isVisible: Bool
    
    let content: () -> Content
    let menu: () -> MenuContent
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var resizeOffset = CGSize.zero
    @State var resizeDelta = CGSize.zero
    let minSize: CGSize = .init(width: 200, height: 200)
    
    /// Our canvas size in screen coordinates, this is used only to avoid the keyboard if it shows up
    @State var floatingAbsoluteFrame: CGRect = .zero
    @State var keyboardAbsoluteFrame: CGRect = .zero
    
    // When the keyboard goes away, this variable determines whether we will
    // restore the original window location before the keyboard was moved.
    //
    // If the user manipulated the window while the keyboard is up, we do not restore it
    @State var restoreFrame = true

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
                        
                        if keyboardAbsoluteFrame.height != 0 {
                            restoreFrame = false
                        }
                    } else if isResizing {
                        position.x += resizeDelta.width/2
                        position.y += resizeDelta.height/2
                        size.width += resizeDelta.width
                        size.height += resizeDelta.height

                        resizeDelta = .zero
                        isResizing = false
                        
                        // If the keyboard is showing and the user resized, do not restore the old
                        
                        if keyboardAbsoluteFrame.height != 0 {
                            restoreFrame = false
                        }
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardAbsoluteFrame = keyboardFrame
                
                oldPosition = position
                oldSize = size
                if keyboardAbsoluteFrame.height > 0, keyboardAbsoluteFrame.minY < floatingAbsoluteFrame.maxY {
                    // Ok, our window would be obscured by the keyboard coming up from below, so we need to
                    // change its position, but first, make sure we have space for it, and also adjust the
                    // size (just the height)
                    
                    // How much space do we actually have?
                    // turn our floatingAbsoluteFrame.origin into the local coordinate, based on
                    // its position and size (because the position is to the middle, we have to do the
                    // size.height/2 dance
                    let diffY = floatingAbsoluteFrame.origin.y - (position.y - size.height/2)

                    let available = containerSize.height + diffY - keyboardAbsoluteFrame.height

                    restoreFrame = true
                    withAnimation {
                        // If we do not have enough space, shrink the window
                        if available < size.height {
                            size.height = available
                            position = CGPoint(
                                x: position.x,
                                y: available/2)
                        } else {
                            // We have space, so just reposition
                            position = CGPoint(
                                x: position.x,
                                y: position.y - (floatingAbsoluteFrame.maxY - keyboardAbsoluteFrame.minY)
                            )
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardAbsoluteFrame = .zero
            if restoreFrame {
                withAnimation {
                    position = oldPosition
                    size = oldSize
                }
            }
        }
    }
    @State var oldPosition = CGPoint.zero
    @State var oldSize = CGSize.zero
    
    @ViewBuilder
    private var titleBar: some View {
        HStack {
            menu()
            Spacer()
            Text(title)
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
