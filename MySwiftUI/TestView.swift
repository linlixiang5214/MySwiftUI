//


import SwiftUI

struct TestView: View {
    
    let count: Int
    
    var bgColor: Color = .orange
    
    var flag: String = ""
    
    var body: some View {
        VStack {
            Text("\(flag.isEmpty ? "来到广州就是靓仔": flag)  index: \(count)")
                .font(.system(size: 16))
                .foregroundStyle(.pink.opacity(0.5))
            
            Spacer().frame(height: 3)
    
            Text("- 来年太慢，今年暴富 -")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.red)
        }
        .frame(width: 260, height: 60)
        .background(bgColor.opacity(0.3))
        .clipShape(.capsule)
    }
}
