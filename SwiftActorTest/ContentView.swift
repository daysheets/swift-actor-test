import SwiftUI

@globalActor
actor WorkActor {
    static let shared = WorkActor()
}

// sortData simulates sorting a large dataset that would take significant time
func sortData() -> String {
    Thread.sleep(forTimeInterval: 15)
    return UUID().uuidString
}

@MainActor
class ViewModelOne: ObservableObject {
    @Published private(set) var data: String?

    func doWork() async {
        data = sortData()
    }
}

@MainActor
class ViewModelTwo: ObservableObject {
    @Published private(set) var data: String?

    private func setData(_ newData: String) { data = newData }

    @WorkActor func doWork() async {
        await setData(sortData())
    }
}

struct ContentView: View {
    @StateObject private var viewModelOne = ViewModelOne()
    @StateObject private var viewModelTwo = ViewModelTwo()

    @State var counter: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("counter: \(counter)")
            HStack {
                Button(action: {
                    Task { await viewModelOne.doWork() }
                }) { Text("Main Actor").padding() }
                Text(viewModelOne.data ?? "No Data")
            }

            HStack {
                Button(action: {
                    Task { await viewModelTwo.doWork() }
                }) { Text("Work Actor").padding() }
                Text(viewModelTwo.data ?? "No Data")
            }
        }
        .padding()
        .task {
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                counter += 1
            }
        }
    }
}
