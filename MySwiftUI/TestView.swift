//


import SwiftUI

struct TestView: View {
    
    let count: Int
    
    var body: some View {
        VStack {
            Text("来到广州就是靓仔 - \(count)")
                .font(.system(size: 16))
                .foregroundStyle(.pink.opacity(0.5))
            
            Spacer().frame(height: 3)
    
            Text("- 来年太慢，今年暴富 -")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.red)
        }
        .frame(width: 260, height: 60)
        .background(.orange.opacity(0.3))
        .clipShape(.capsule)
    }
}
