//
//  FilterSortSheet.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

struct FilterSortSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var searchManager: TripSearchManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sort By") {
                    ForEach(TripSearchManager.SortOption.allCases, id: \.self) { option in
                        Button {
                            searchManager.sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if searchManager.sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Filter") {
                    ForEach(TripSearchManager.SharedFilter.allCases, id: \.self) { filter in
                        Button {
                            searchManager.filterByShared = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if searchManager.filterByShared == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("Reset to Defaults") {
                        searchManager.sortOption = .dateNewest
                        searchManager.filterByShared = .all
                        searchManager.searchText = ""
                        ToastManager.shared.show("Filters reset", type: .success)
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Sort & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Activity Filter Sheet
struct ActivityFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var filterManager: ActivityFilterManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    ForEach(ActivityFilterManager.ActivityCategory.allCases, id: \.self) { category in
                        Button {
                            filterManager.selectedCategory = category
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(filterManager.selectedCategory == category ? .blue : .secondary)
                                
                                Text(category.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if filterManager.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Sort By") {
                    ForEach(ActivityFilterManager.ActivitySort.allCases, id: \.self) { sort in
                        Button {
                            filterManager.sortBy = sort
                        } label: {
                            HStack {
                                Text(sort.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if filterManager.sortBy == sort {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Completion Status") {
                    Toggle("Show Completed Only", isOn: $filterManager.showCompletedOnly)
                        .onChange(of: filterManager.showCompletedOnly) { _, newValue in
                            if newValue {
                                filterManager.showIncompleteOnly = false
                            }
                        }
                    
                    Toggle("Show Incomplete Only", isOn: $filterManager.showIncompleteOnly)
                        .onChange(of: filterManager.showIncompleteOnly) { _, newValue in
                            if newValue {
                                filterManager.showCompletedOnly = false
                            }
                        }
                }
                
                Section {
                    Button("Reset to Defaults") {
                        filterManager.selectedCategory = .all
                        filterManager.sortBy = .order
                        filterManager.showCompletedOnly = false
                        filterManager.showIncompleteOnly = false
                        ToastManager.shared.show("Filters reset", type: .success)
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Filter Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
