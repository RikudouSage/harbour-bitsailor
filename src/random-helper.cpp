#include "random-helper.h"
#include <sys/random.h>

const QString generateRandomString(std::size_t length)
{
    constexpr char charset[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz";


    const size_t charsetSize = sizeof(charset) - 1;

    std::string result;
    result.reserve(length);

    for (std::size_t i = 0; i < length; ++i) {
        unsigned char randomByte;
        ssize_t bytesRead = getrandom(&randomByte, sizeof(randomByte), 0);
        if (bytesRead != sizeof(randomByte)) {
            throw std::runtime_error("Failed to get random byte.");
        }

        // To avoid modulo bias, only accept bytes below the largest multiple of charsetSize
        // that fits in a byte (i.e. 256 - (256 % charsetSize)).
        const unsigned int maxAcceptable = 256 - (256 % charsetSize);
        while (randomByte >= maxAcceptable) {
            bytesRead = getrandom(&randomByte, sizeof(randomByte), 0);
            if (bytesRead != sizeof(randomByte)) {
                throw std::runtime_error("Failed to get random byte.");
            }
        }
        result.push_back(charset[randomByte % charsetSize]);
    }

    return QString::fromStdString(result);
}

const QString generateRandomPin(int pinLength)
{
    constexpr char digits[] = "0123456789";
    constexpr int digitsCount = 10;
    QString result;
    result.reserve(pinLength);

    for (int i = 0; i < pinLength; ++i) {
        unsigned char randomByte;
        ssize_t bytesRead = getrandom(&randomByte, sizeof(randomByte), GRND_RANDOM);
        if (bytesRead != sizeof(randomByte)) {
            throw std::runtime_error("Failed to obtain secure random data.");
        }

        // Avoid modulo bias by only accepting values less than the largest
        // multiple of digitsCount that fits in a byte.
        const unsigned int maxAcceptable = 256 - (256 % digitsCount);
        while (randomByte >= maxAcceptable) {
            bytesRead = getrandom(&randomByte, sizeof(randomByte), GRND_RANDOM);
            if (bytesRead != sizeof(randomByte)) {
                throw std::runtime_error("Failed to obtain secure random data.");
            }
        }
        int digitIndex = randomByte % digitsCount;
        result.append(digits[digitIndex]);
    }

    return result;
}
