<?php

declare(strict_types=1);

namespace App\CLI\Client\WebToElasticms\Helper;

use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\PropertyInfo\Extractor\PhpDocExtractor;
use Symfony\Component\PropertyInfo\Extractor\ReflectionExtractor;
use Symfony\Component\PropertyInfo\PropertyInfoExtractor;
use Symfony\Component\Serializer\Encoder\JsonEncode;
use Symfony\Component\Serializer\Encoder\JsonEncoder;
use Symfony\Component\Serializer\Encoder\XmlEncoder;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\ArrayDenormalizer;
use Symfony\Component\Serializer\Normalizer\ObjectNormalizer;
use Symfony\Component\Serializer\Serializer;

class Url
{
    private const ABSOLUTE_SCHEME = ['mailto', 'javascript', 'tel'];
    private readonly string $scheme;
    private readonly string $host;
    private readonly ?int $port;
    private readonly ?string $user;
    private readonly ?string $password;
    private readonly string $path;
    private readonly ?string $query;
    private readonly ?string $fragment;
    private readonly ?string $referer;

    public function __construct(string $url, ?string $referer = null, private readonly ?string $refererLabel = null)
    {
        $parsed = self::mb_parse_url($url);
        $relativeParsed = [];
        if (null !== $referer) {
            $relativeParsed = self::mb_parse_url($referer);
        }

        $scheme = $parsed['scheme'] ?? $relativeParsed['scheme'] ?? null;
        if (null === $scheme) {
            throw new \RuntimeException(\sprintf('Unexpected null scheme: %s with referer: %s', $url, $referer));
        }
        $this->scheme = $scheme;

        $host = $parsed['host'] ?? $relativeParsed['host'] ?? null;
        if (null === $host) {
            throw new \RuntimeException('Unexpected null host');
        }
        $this->host = $host;

        $this->referer = null === $referer ? null : (new Url($referer))->getUrl(null, true);
        $this->user = $parsed['user'] ?? $relativeParsed['user'] ?? null;
        $this->password = $parsed['pass'] ?? $relativeParsed['pass'] ?? null;
        $this->port = $parsed['port'] ?? $relativeParsed['port'] ?? null;
        $this->query = $parsed['query'] ?? null;
        $this->fragment = $parsed['fragment'] ?? null;

        $this->path = $this->getAbsolutePath($parsed['path'] ?? '/', $relativeParsed['path'] ?? '/');
    }

    public function serialize(string $format = JsonEncoder::FORMAT): string
    {
        return self::getSerializer()->serialize($this, $format, [AbstractNormalizer::IGNORED_ATTRIBUTES => [
            'query',
            'scheme',
            'host',
            'port',
            'user',
            'password',
            'path',
            'fragment',
            'filename',
            'crawlable',
            'id',
        ]]);
    }

    public static function deserialize(string $data, string $format = JsonEncoder::FORMAT): Url
    {
        $url = self::getSerializer()->deserialize($data, Url::class, $format);
        if (!$url instanceof Url) {
            throw new \RuntimeException('Unexpected non Cache object');
        }

        return $url;
    }

    private static function getSerializer(): Serializer
    {
        $reflectionExtractor = new ReflectionExtractor();
        $phpDocExtractor = new PhpDocExtractor();
        $propertyTypeExtractor = new PropertyInfoExtractor([$reflectionExtractor], [$phpDocExtractor, $reflectionExtractor], [$phpDocExtractor], [$reflectionExtractor], [$reflectionExtractor]);

        return new Serializer([
            new ArrayDenormalizer(),
            new ObjectNormalizer(null, null, null, $propertyTypeExtractor),
        ], [
            new XmlEncoder(),
            new JsonEncoder(new JsonEncode([JsonEncode::OPTIONS => JSON_UNESCAPED_SLASHES]), null),
        ]);
    }

    private function getAbsolutePath(string $path, string $relativeToPath): string
    {
        if (\in_array($this->getScheme(), self::ABSOLUTE_SCHEME)) {
            return $path;
        }
        if ('/' !== \substr($relativeToPath, \strlen($relativeToPath) - 1)) {
            $lastSlash = \strripos($relativeToPath, '/');
            if (false === $lastSlash) {
                $relativeToPath .= '/';
            } else {
                $relativeToPath = \substr($relativeToPath, 0, $lastSlash + 1);
            }
        }

        if (!\str_starts_with($path, '/')) {
            $path = $relativeToPath.$path;
        }
        $patterns = ['#(/\.?/)#', '#/(?!\.\.)[^/]+/\.\./#'];
        for ($n = 1; $n > 0;) {
            $path = \preg_replace($patterns, '/', $path, -1, $n);
            if (!\is_string($path)) {
                throw new \RuntimeException(\sprintf('Unexpected non string path %s', $path));
            }
        }
        if (!\str_starts_with($path, '/')) {
            $path = '/'.$path;
        }

        return $path;
    }

    public function getUrl(string $path = null, bool $withFragment = false): string
    {
        if (null !== $path) {
            return (new Url($path, $this->getUrl()))->getUrl(null, $withFragment);
        }
        if (\in_array($this->getScheme(), self::ABSOLUTE_SCHEME)) {
            $url = \sprintf('%s:', $this->scheme);
        } elseif (null !== $this->user && null !== $this->password) {
            $url = \sprintf('%s://%s:%s@%s', $this->scheme, $this->user, $this->password, $this->host);
        } else {
            $url = \sprintf('%s://%s', $this->scheme, $this->host);
        }
        if (null !== $this->port) {
            $url = \sprintf('%s:%d%s', $url, $this->port, $this->path);
        } else {
            $url = \sprintf('%s%s', $url, $this->path);
        }
        if (null !== $this->query) {
            $url = \sprintf('%s?%s', $url, $this->query);
        }
        if ($withFragment && null !== $this->fragment) {
            $url = \sprintf('%s#%s', $url, $this->fragment);
        }

        return $url;
    }

    public function getScheme(): string
    {
        return $this->scheme;
    }

    public function getHost(): string
    {
        return $this->host;
    }

    public function getPort(): ?int
    {
        return $this->port;
    }

    public function getUser(): ?string
    {
        return $this->user;
    }

    public function getPassword(): ?string
    {
        return $this->password;
    }

    public function getPath(): string
    {
        return $this->path;
    }

    public function getQuery(): ?string
    {
        return $this->query;
    }

    public function getFragment(): ?string
    {
        return $this->fragment;
    }

    public function getFilename(): string
    {
        $exploded = \explode('/', $this->path);
        $name = \array_pop($exploded);
        if ('' === $name) {
            return 'index.html';
        }

        return $name;
    }

    public function getReferer(): ?string
    {
        return $this->referer;
    }

    public function isCrawlable(): bool
    {
        return \in_array($this->getScheme(), ['http', 'https']);
    }

    public function getId(): string
    {
        return \sha1($this->getUrl());
    }

    /**
     * @return array{scheme?: string, host?: string, port?: int, user?: string, pass?: string, query?: string, path?: string, fragment?: string}
     */
    public static function mb_parse_url(string $url): array
    {
        $enc_url = \preg_replace_callback(
            '%[^:/@?&=#]+%usD',
            fn ($matches) => \urlencode((string) $matches[0]),
            $url
        );

        if (null === $enc_url) {
            throw new \RuntimeException(\sprintf('Unexpected wrong url %s', $url));
        }

        $parts = \parse_url($enc_url);

        if (false === $parts) {
            throw new \RuntimeException(\sprintf('Unexpected wrong url %s', $url));
        }

        foreach ($parts as $name => $value) {
            if (\is_int($value)) {
                continue;
            }
            $parts[$name] = \urldecode($value);
        }

        $optionsResolver = new OptionsResolver();
        $optionsResolver->setDefaults([
            'scheme' => null,
            'host' => null,
            'port' => null,
            'user' => null,
            'pass' => null,
            'path' => null,
            'query' => null,
            'fragment' => null,
        ]);
        $optionsResolver->setAllowedTypes('scheme', ['string', 'null']);
        $optionsResolver->setAllowedTypes('host', ['string', 'null']);
        $optionsResolver->setAllowedTypes('port', ['int', 'null']);
        $optionsResolver->setAllowedTypes('user', ['string', 'null']);
        $optionsResolver->setAllowedTypes('pass', ['string', 'null']);
        $optionsResolver->setAllowedTypes('path', ['string', 'null']);
        $optionsResolver->setAllowedTypes('query', ['string', 'null']);
        $optionsResolver->setAllowedTypes('fragment', ['string', 'null']);

        $resolved = $optionsResolver->resolve($parts);
        /* @var array{scheme?: string, host?: string, port?: int, user?: string, pass?: string, query?: string, path?: string, fragment?: string} $resolved */
        return $resolved;
    }

    public function getRefererLabel(): ?string
    {
        return $this->refererLabel;
    }
}
