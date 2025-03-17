<?php

const CONTEXT_DESKTOP_FILE = 'DesktopFile';
const CONTEXT_POLKIT_FILE = 'PolkitFile';

$desktopFile = __DIR__ . '/../harbour-bitsailor.desktop';
$polkitFile = __DIR__ . '/../polkit/cz.chrastecky.bitsailor.policy';

$regex = /** @lang RegExp */ '@harbour-bitsailor-(.{2})\.ts@';
foreach (glob(__DIR__ . '/*.ts') as $file) {
    if (!preg_match($regex, $file, $matches)) {
        continue;
    }

    $lang = $matches[1];
    $xml = new SimpleXMLElement(file_get_contents($file));
    foreach ($xml->context as $context) {
        if ((string) $context->name === CONTEXT_DESKTOP_FILE) {
            foreach ($context->message as $message) {
                $translation = (string) $message->translation;
                $desktop = array_map('trim', file($desktopFile));

                $foundName = false;
                $rawNameLineNumber = -1;
                $targetNameLineNumber = -1;

                $foundShare = false;
                $rawShareLineNumber = -1;
                $targetShareLineNumber = -1;

                $foundShareSection = false;

                foreach ($desktop as $lineNumber => $lineContent) {
                    if (str_starts_with($lineContent, "Name=")) {
                        $rawNameLineNumber = $lineNumber;
                    }
                    if (str_starts_with($lineContent, "Name[{$lang}]=")) {
                        $foundName = true;
                        $targetNameLineNumber = $lineNumber;
                    }

                    if ($lineContent === '[X-Share Method anything]') {
                        $foundShareSection = true;
                    }

                    if ($foundShareSection) {
                        if (str_starts_with($lineContent, 'Description=')) {
                            $rawShareLineNumber = $lineNumber;
                        }
                        if (str_starts_with($lineContent, "Description[{$lang}]=")) {
                            $foundShare = true;
                            $targetShareLineNumber = $lineNumber;
                        }
                    }
                }

                assert($rawNameLineNumber >= 0);
                assert($rawShareLineNumber >= 0);

                if ((string) $message->source === 'BitSailor') {
                    if (!$foundName) {
                        array_splice($desktop, $rawNameLineNumber + 1, 0, "Name[{$lang}]={$translation}");
                    } else {
                        $desktop[$targetNameLineNumber] = "Name[{$lang}]={$translation}";
                    }
                }
                if ((string) $message->source === 'Share via Send') {
                    if (!$foundShare) {
                        array_splice($desktop, $rawShareLineNumber + 1, 0, "Description[{$lang}]={$translation}");
                    } else {
                        $desktop[$targetShareLineNumber] = "Description[{$lang}]={$translation}";
                    }
                }

                file_put_contents($desktopFile, implode("\n", $desktop));
            }
        }
        if ((string) $context->name === CONTEXT_POLKIT_FILE) {
            $translation = (string) $context->message->translation;
            $polkit = new SimpleXMLElement(file_get_contents($polkitFile));
            $ns = $polkit->getNamespaces(true);
            $ns['xml'] ??= 'http://www.w3.org/XML/1998/namespace';
            $messages = $polkit->action->message;

            $foundName = false;

            foreach ($messages as $message) {
                assert($message instanceof SimpleXMLElement);
                $messageLang = (string) $message->attributes($ns['xml'])['lang'];
                if (!$messageLang) {
                    continue;
                }
                if ($messageLang !== $lang) {
                    continue;
                }
                $message[0] = $translation;
                $foundName = true;
                break;
            }

            if (!$foundName) {
                $newMessage = $polkit->action->addChild('message', $translation);
                $newMessage->addAttribute('xml:lang', $lang, $ns['xml']);
            }

            file_put_contents($polkitFile, $polkit->asXML());
        }
    }
}
