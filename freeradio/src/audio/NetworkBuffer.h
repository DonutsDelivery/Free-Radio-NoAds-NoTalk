#pragma once

#include <atomic>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <vector>

namespace FreeRadio::Audio {

class NetworkBuffer
{
public:
    static constexpr int EndOfStream = 0;
    static constexpr int Cancelled = -1;

    explicit NetworkBuffer(std::size_t capacityBytes = 1024 * 1024);

    std::size_t append(const char *data, std::size_t size);
    int read(unsigned char *destination, int requested);
    std::size_t freeSpace() const;
    void resetForRange(std::int64_t offset);
    void setTotalSize(std::int64_t size);
    std::int64_t position() const;
    std::int64_t totalSize() const;
    void finish();
    void cancel();
    bool isCancelled() const { return m_cancelled.load(std::memory_order_acquire); }

private:
    mutable std::mutex m_mutex;
    std::condition_variable m_readable;
    std::vector<unsigned char> m_storage;
    std::size_t m_read = 0;
    std::size_t m_write = 0;
    std::size_t m_size = 0;
    std::int64_t m_position = 0;
    std::int64_t m_totalSize = -1;
    bool m_finished = false;
    std::atomic<bool> m_cancelled{false};
};

} // namespace FreeRadio::Audio
