#include "SpectrumAnalyzer.h"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace FreeRadio::Audio {
namespace {
constexpr float Pi = 3.14159265358979323846f;
}

SpectrumAnalyzer::SpectrumAnalyzer(std::size_t fftSize)
    : m_fftSize(fftSize), m_window(static_cast<qsizetype>(fftSize)),
      m_history(static_cast<qsizetype>(fftSize / 2), 0.0f),
      m_result(static_cast<qsizetype>(fftSize / 2), 0.0f),
      m_values(static_cast<qsizetype>(fftSize))
{
    if (fftSize < 2 || (fftSize & (fftSize - 1)) != 0)
        throw std::invalid_argument("FFT size must be a power of two");
    for (std::size_t i = 0; i < fftSize; ++i)
        m_window[static_cast<qsizetype>(i)] = 0.5f - 0.5f * std::cos(2.0f * Pi * i
                                                                    / static_cast<float>(fftSize - 1));
}

void SpectrumAnalyzer::transform()
{
    const std::size_t size = static_cast<std::size_t>(m_values.size());
    for (std::size_t i = 1, j = 0; i < size; ++i) {
        std::size_t bit = size >> 1;
        for (; j & bit; bit >>= 1)
            j ^= bit;
        j ^= bit;
        if (i < j)
            std::swap(m_values[static_cast<qsizetype>(i)], m_values[static_cast<qsizetype>(j)]);
    }
    for (std::size_t length = 2; length <= size; length <<= 1) {
        const float angle = -2.0f * Pi / static_cast<float>(length);
        const std::complex<float> step(std::cos(angle), std::sin(angle));
        for (std::size_t start = 0; start < size; start += length) {
            std::complex<float> factor(1.0f, 0.0f);
            for (std::size_t offset = 0; offset < length / 2; ++offset) {
                auto &even = m_values[static_cast<qsizetype>(start + offset)];
                auto &odd = m_values[static_cast<qsizetype>(start + offset + length / 2)];
                const auto product = factor * odd;
                const auto original = even;
                even = original + product;
                odd = original - product;
                factor *= step;
            }
        }
    }
}

QVector<float> SpectrumAnalyzer::analyze(const float *interleaved, std::size_t frames, int channels)
{
    if (!interleaved || frames < m_fftSize || channels < 1)
        return {};
    const auto first = frames - m_fftSize;
    for (std::size_t i = 0; i < m_fftSize; ++i) {
        float mono = 0.0f;
        for (int channel = 0; channel < channels; ++channel)
            mono += interleaved[(first + i) * static_cast<std::size_t>(channels) + channel];
        mono /= static_cast<float>(channels);
        m_values[static_cast<qsizetype>(i)] = mono * m_window[static_cast<qsizetype>(i)];
    }
    transform();
    for (qsizetype i = 0; i < m_result.size(); ++i) {
        const float magnitude = 2.0f * std::abs(m_values[i]) / static_cast<float>(m_fftSize);
        m_result[i] = 0.65f * m_history[i] + 0.35f * magnitude;
    }
    m_history = m_result;
    return m_result;
}

} // namespace FreeRadio::Audio
