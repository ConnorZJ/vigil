import Foundation

protocol RepeatingTask {
    func cancel()
}

protocol RepeatingTaskScheduling {
    @discardableResult
    func scheduleRepeating(every interval: TimeInterval, _ action: @escaping () -> Void) -> RepeatingTask
}

struct TimerRepeatingTaskScheduler: RepeatingTaskScheduling {
    @discardableResult
    func scheduleRepeating(every interval: TimeInterval, _ action: @escaping () -> Void) -> RepeatingTask {
        TimerRepeatingTask(timer: Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        })
    }
}

private final class TimerRepeatingTask: RepeatingTask {
    private var timer: Timer?

    init(timer: Timer) {
        self.timer = timer
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
