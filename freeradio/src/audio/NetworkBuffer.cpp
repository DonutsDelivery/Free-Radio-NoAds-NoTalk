#include "NetworkBuffer.h"

#include <algorithm>
#include <cstring>

namespace FreeRadio::Audio {

NetworkBuffer::NetworkBuffer(std::size_t capacityBytes)
    : m_storage(capacityBytes)
{
}

std::size_t NetworkBuffer::append(const char *data, std::size_t size)
{
    QMutexLocker lock(&m_mutex);
    if (m_cancelled.load(std::memory_order_relaxed) || m_finished)
        return 0;
    const auto count = std::min(size, m_storage.size() - m_size);
    const auto first = std::min(count, m_storage.size() - m_write);
    std::memcpy(m_storage.data() + m_write, data, first);
    std::memcpy(m_storage.data(), data + first, count - first);
    m_write = (m_write + count) % m_storage.size();
    m_size += count;
    if (count)
        m_readable.wakeOne();
    return count;
}

int NetworkBuffer::read(unsigned char *destination, int requested)
{
    QMutexLocker lock(&m_mutex);
    while (m_size == 0 && !m_finished && !m_cancelled.load(std::memory_order_relaxed))
        m_readable.wait(&m_mutex);
    if (m_cancelled.load(std::memory_order_relaxed))
        return Cancelled;
    if (m_size == 0 && m_finished)
        return EndOfStream;
    const auto count = std::min<std::size_t>(static_cast<std::size_t>(requested), m_size);
    const auto first = std::min(count, m_storage.size() - m_read);
    std::memcpy(destination, m_storage.data() + m_read, first);
    std::memcpy(destination + first, m_storage.data(), count - first);
    m_read = (m_read + count) % m_storage.size();
    m_size -= count;
    return static_cast<int>(count);
}

std::size_t NetworkBuffer::freeSpace() const
{
    QMutexLocker lock(&m_mutex);
    return m_storage.size() - m_size;
}

void NetworkBuffer::finish()
{
    QMutexLocker lock(&m_mutex);
    m_finished = true;
    m_readable.wakeAll();
}

void NetworkBuffer::cancel()
{
    QMutexLocker lock(&m_mutex);
    m_cancelled.store(true, std::memory_order_release);
    m_readable.wakeAll();
}

} // namespace FreeRadio::Audio
