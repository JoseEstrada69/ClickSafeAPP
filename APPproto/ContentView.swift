//
//  ContentView.swift
//  APPproto
//
//  Created by alumno on 04/09/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                
                Text("Hola, SwiftUI")
                    .font(.title)
                    .foregroundColor(.black)
                
                Button("Prueba RegUsuario") {
                    print("Botón presionado")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
