import ComposableArchitecture
import SpacedRepetitionScheduler
import SwiftUI
import Utilities

@ViewAction(for: HawWordStudyReducer.self)
public struct HawWordStudyView: View {
  @Perception.Bindable public var store: StoreOf<HawWordStudyReducer>
  public init(store: StoreOf<HawWordStudyReducer>) {
    self.store = store
    print("Booting up HawWordStudyView")
  }
  
  
  public var body: some View {
    VStack {
      
      switch store.studySession.status {
        case .active: self.activeView
        case .finished: self.finishedView
      }
      self.debugView
    }
    
    
  }
  
  @ViewBuilder public var activeView: some View {
    if let currentPrompt = store.studySession.queue[safe: store.studySession.currentIndex] {
      self.currentPromptView(currentPrompt)
    } else {
      Text("No current prompt")
    }
  }
  
  @ViewBuilder public var finishedView: some View {
    Text("🎉 You finished your study session")
  }
  
  @ViewBuilder public func currentPromptView(_ prompt: SpacedPrompt<HawWord>) -> some View {
    VStack {
      LabeledContent("Question", value: prompt.value.question)
      LabeledContent("Answer", value: prompt.value.answer)
      
      self.recallEaseButtons
    }
  }
  
  @ViewBuilder public var debugView: some View {
    GroupBox("Debug View") {
      if let errorString = store.errorMessage {
        LabeledContent("Error", value: errorString).font(.title).tint(.red)
      }
      LabeledContent("Current prompt mode", value: store.studySession.currentPrompt?.promptSchedulingMetadata.mode.debugDescription ?? "nil")
      LabeledContent("Study session status", value: store.studySession.status.debugDescription)
      LabeledContent("Study session mode", value: store.studySession.mode.debugDescription)
    }
  }
  
  
  @ViewBuilder public var recallEaseButtons: some View {
    HStack {
      Button("Again") {
        send(.onTapAgain, animation: .default)
      }.tint(.red)
      if !store.studySession.currentPromptIsLearning {
        Button("Hard") {
          send(.onTapHard, animation: .default)
        }.tint(.orange)
      }
      
      Button("Good") {
        send(.onTapGood, animation: .default)
      }.tint(.green)
      Button("Easy") {
        send(.onTapEasy, animation: .default)
      }
    }.buttonStyle(.borderedProminent)
  }
}

// MARK: Previews
// Macro #Preview s confict with macro @Reducer
//#Preview("HawWordStudyView") {
//  let store = StoreOf<HawWordStudyReducer>(
//    initialState: HawWordStudyReducer.State(),
//    reducer: {
//      HawWordStudyReducer()
//        ._printChanges()
//    }
//  )
//  
//  return HawWordStudyView(store: store)
//}

#if DEBUG
struct HawWordStudyView_Previews: PreviewProvider {
  
  static var previews: some View {
    HawWordStudyView(store: Store(
      initialState: HawWordStudyReducer.State(),
      reducer: {
        HawWordStudyReducer()
          ._printChanges()
      },
      withDependencies: {
        $0.uuid = .incrementing
      })
    )
  }
}
#endif


