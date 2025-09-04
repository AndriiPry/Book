//
//  NavbarView.swift
//  AudioLibrary
//
//  Created by Oleksii on 03.09.2025.
//
import SwiftUI

struct SearchView: View {
    var body: some View {
        Text("Search")
    }
}

struct SavedView: View {
    var body: some View {
        Text("Saved")
    }
}

struct YouView: View {
    var body: some View {
        Text("You")
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Environment object to control tab bar visibility
class TabBarVisibility: ObservableObject {
    @Published var isHidden: Bool = false
    @Published var isDisabled: Bool = false
}

struct NavbarView<SearchView: View, SavedView: View, YouView: View, HomeView: View>: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    
    let searchView: () -> SearchView
    let savedView: () -> SavedView
    let youView: () -> YouView
    let homeView: () -> HomeView
    
    init(
        selectedTab: Binding<Int>,
        @ViewBuilder searchView: @escaping () -> SearchView,
        @ViewBuilder savedView: @escaping () -> SavedView,
        @ViewBuilder youView: @escaping () -> YouView,
        @ViewBuilder homeView: @escaping () -> HomeView
    ) {
        self._selectedTab = selectedTab
        self.searchView = searchView
        self.savedView = savedView
        self.youView = youView
        self.homeView = homeView
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mainContent
            tabBarContent
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // Start with Home tab (tag 3)
            if selectedTab != 3 {
                selectedTab = 3
            }
        }
    }

    private var mainContent: some View {
        ZStack {
            searchView()
                .opacity(selectedTab == 0 ? 1 : 0)
            
            savedView()
                .opacity(selectedTab == 1 ? 1 : 0)
            
            youView()
                .opacity(selectedTab == 2 ? 1 : 0)
            
            homeView()
                .opacity(selectedTab == 3 ? 1 : 0)
        }
        .padding(.bottom, tabBarVisibility.isHidden ? 0 : 90)
        .background(tabBarVisibility.isHidden ? .clear : .white)
    }

    private var tabBarContent: some View {
        ZStack {
            tabItems
                .padding(.top, 13)
                .opacity(tabBarVisibility.isHidden ? 0 : 1)
                .background(tabBarVisibility.isHidden ? .clear : .white)
                .animation(.easeInOut(duration: 0.3), value: tabBarVisibility.isHidden)
        }
        .frame(height: 110)
        .clipped()
    }
    
    private var tabItems: some View {
        HStack {
            ForEach(0..<4) { tabIndex in
                Spacer()
                tabButton(for: tabIndex)
                Spacer()
            }
        }
        .padding(.bottom, 20)
    }

    private func tabButton(for tabIndex: Int) -> some View {
        Button(action: {
            if !tabBarVisibility.isDisabled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tabIndex
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tabIcon(tabIndex))
                    .font(.system(size: 25, weight: selectedTab == tabIndex ? .bold : .regular))
                Text(tabTitle(for: tabIndex))
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tabIndex ? Color(red: 0.3, green: 0.4, blue: 0.7) : .black)
        }
        .disabled(tabBarVisibility.isDisabled)
    }

    private func tabTitle(_ index: Int) -> String {
        switch index {
        case 0: return "Search"
        case 1: return "Saved"
        case 2: return "You"
        case 3: return "Home"
        default: return ""
        }
    }
    
    private func tabIcon(_ index: Int) -> String {
        switch index {
        case 0: return "magnifyingglass"
        case 1: return "bookmark"
        case 2: return "person"
        case 3: return "house"
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Search"
        case 1: return "Saved"
        case 2: return "You"
        case 3: return "Home"
        default: return ""
        }
    }
}

struct NavbarViewContainer: View {
    @StateObject private var tabBarVisibility = TabBarVisibility()
    @State private var selectedTab = 3
    @AppStorage("termsAccepted") private var termsAccepted: Bool?
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    
    var body: some View {
        Group {
            if termsAccepted == nil {
                TermsAndConditionsView(termsAccepted: $termsAccepted)
            } else if termsAccepted == true {
                if !isSignedIn {
                    SignInView(isSignedIn: $isSignedIn)
                } else {
                    NavbarView(selectedTab: $selectedTab) {
                        SearchView()
                    } savedView: {
                        SavedView()
                    } youView: {
                        YouView()
                    } homeView: {
                        HomeView()
                    }
                    .environmentObject(tabBarVisibility)
                }
            } else {
                TermsDeclinedView(termsAccepted: $termsAccepted)
            }
        }
    }
}

struct NavbarView_Previews: PreviewProvider {
    static var previews: some View {
        NavbarViewContainer()
    }
}
