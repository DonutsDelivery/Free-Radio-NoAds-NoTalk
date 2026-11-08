#pragma once

#include <QVector>
#include <complex>
#include <cstddef>

namespace FreeRadio::Audio {

class SpectrumAnalyzer
{
public:
    explicit SpectrumAnalyzer(std::size_t fftSize = 1024);

    std::size_t fftSize() const { return m_fftSize; }
    QVector<float> analyze(const float *interleaved, std::size_t frames, int channels);

private:
    void transform();

    std::size_t m_fftSize;
    QVector<float> m_window;
    QVector<float> m_history;
    QVector<float> m_result;
    QVector<std::complex<float>> m_values;
};

} // namespace FreeRadio::Audio
