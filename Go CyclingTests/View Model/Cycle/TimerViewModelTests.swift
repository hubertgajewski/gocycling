//
//  TimerViewModelTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

private func waitShortInterval() {
  Thread.sleep(forTimeInterval: 0.05)
}

@Suite("TimerViewModel")
struct TimerViewModelTests {

  @Test("initial state is stopped with zero accumulated time")
  func initialStateIsStopped() {
    let timer = TimerViewModel()

    #expect(timer.isStopped)
    #expect(!timer.isRunning)
    #expect(!timer.isPaused)
    #expect(timer.totalAccumulatedTime == 0)
  }

  @Test("start transitions to running state")
  func startTransitionsToRunning() {
    let timer = TimerViewModel()
    defer { timer.stop() }

    timer.start()

    #expect(timer.isRunning)
    #expect(!timer.isPaused)
    #expect(!timer.isStopped)
  }

  @Test("pause records elapsed time while running")
  func pauseRecordsElapsedTime() async {
    let timer = TimerViewModel()
    timer.start()

    waitShortInterval()

    timer.pause()

    #expect(timer.isPaused)
    #expect(!timer.isRunning)
    #expect(!timer.isStopped)
    #expect(timer.totalAccumulatedTime > 0)
  }

  @Test("resume preserves and continues accumulating time")
  func resumePreservesAndContinuesAccumulatingTime() async {
    let timer = TimerViewModel()
    timer.start()

    waitShortInterval()
    timer.pause()

    let pausedTime = timer.totalAccumulatedTime

    timer.start()
    #expect(timer.isRunning)

    waitShortInterval()
    timer.pause()

    #expect(timer.totalAccumulatedTime > pausedTime)
  }

  @Test("stop returns to stopped state and clears accumulated time")
  func stopReturnsToStoppedStateAndClearsTime() async {
    let timer = TimerViewModel()
    timer.start()

    waitShortInterval()
    timer.stop()

    #expect(timer.isStopped)
    #expect(!timer.isRunning)
    #expect(!timer.isPaused)
    #expect(timer.totalAccumulatedTime == 0)
  }

  @Test("stop from paused state clears accumulated time")
  func stopFromPausedStateClearsAccumulatedTime() async {
    let timer = TimerViewModel()
    timer.start()

    waitShortInterval()
    timer.pause()
    #expect(timer.totalAccumulatedTime > 0)

    timer.stop()

    #expect(timer.isStopped)
    #expect(timer.totalAccumulatedTime == 0)
  }

  @Test("reset clears accumulated time")
  func resetClearsAccumulatedTime() async {
    let timer = TimerViewModel()
    timer.start()

    waitShortInterval()
    timer.pause()
    #expect(timer.totalAccumulatedTime > 0)

    timer.reset()

    #expect(timer.totalAccumulatedTime == 0)
  }

  @Test("repeated calls on stopped timer remain safe")
  func repeatedCallsOnStoppedTimerRemainSafe() {
    let timer = TimerViewModel()

    timer.pause()
    timer.stop()
    timer.reset()
    timer.pause()
    timer.stop()
    timer.reset()

    #expect(timer.isStopped)
    #expect(!timer.isRunning)
    #expect(!timer.isPaused)
    #expect(timer.totalAccumulatedTime == 0)
  }

  @Test("calling start while running does not change state")
  func callingStartWhileRunningDoesNotChangeState() async {
    let timer = TimerViewModel()
    defer { timer.stop() }

    timer.start()
    #expect(timer.isRunning)

    waitShortInterval()

    timer.start()

    #expect(timer.isRunning)
    #expect(!timer.isPaused)
    #expect(!timer.isStopped)
  }
}
