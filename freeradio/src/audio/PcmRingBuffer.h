#pragma once

#include "../../plugin/miniaudio.h"

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <vector>

namespace FreeRadio::Audio {

class PcmRingBuffer
{
public:
    PcmRingBuffer(std::size_t capacityFrames, unsigned int channels)
        : m_channels(channels), m_storage(capacityFrames * channels)
    {
        m_valid = ma_pcm_rb_init(ma_format_f32, channels, static_cast<ma_uint32>(capacityFrames),
                                 m_storage.data(), nullptr, &m_ring) == MA_SUCCESS;
    }

    ~PcmRingBuffer()
    {
        if (m_valid)
            ma_pcm_rb_uninit(&m_ring);
    }

    PcmRingBuffer(const PcmRingBuffer &) = delete;
    PcmRingBuffer &operator=(const PcmRingBuffer &) = delete;

    bool isValid() const { return m_valid; }
    std::size_t capacityFrames() const { return m_storage.size() / m_channels; }
    std::size_t availableFrames() { return ma_pcm_rb_available_read(&m_ring); }
    std::size_t freeFrames() { return ma_pcm_rb_available_write(&m_ring); }

    std::size_t write(const float *samples, std::size_t frames)
    {
        std::size_t total = 0;
        while (total < frames) {
            ma_uint32 contiguous = static_cast<ma_uint32>(frames - total);
            void *destination = nullptr;
            if (ma_pcm_rb_acquire_write(&m_ring, &contiguous, &destination) != MA_SUCCESS || contiguous == 0)
                break;
            std::memcpy(destination, samples + total * m_channels,
                        static_cast<std::size_t>(contiguous) * m_channels * sizeof(float));
            ma_pcm_rb_commit_write(&m_ring, contiguous);
            total += contiguous;
        }
        return total;
    }

    std::size_t read(float *samples, std::size_t frames)
    {
        std::size_t total = 0;
        while (total < frames) {
            ma_uint32 contiguous = static_cast<ma_uint32>(frames - total);
            void *source = nullptr;
            if (ma_pcm_rb_acquire_read(&m_ring, &contiguous, &source) != MA_SUCCESS || contiguous == 0)
                break;
            std::memcpy(samples + total * m_channels, source,
                        static_cast<std::size_t>(contiguous) * m_channels * sizeof(float));
            ma_pcm_rb_commit_read(&m_ring, contiguous);
            total += contiguous;
        }
        return total;
    }

private:
    unsigned int m_channels;
    std::vector<float> m_storage;
    ma_pcm_rb m_ring{};
    bool m_valid = false;
};

} // namespace FreeRadio::Audio
