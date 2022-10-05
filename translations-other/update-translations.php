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
            $translation = (string) $context->message->translation;
            $desktop = array_map('trim', file($desktopFile));

            $found = false;
            $rawNameLineNumber = -1;
            $targetLineNumber = -1;

            foreach ($desktop as $lineNumber => $lineContent) {
                if (strpos($lineContent, "Name=") === 0) {
                    $rawNameLineNumber = $lineNumber;
                }
                if (strpos($lineContent, "Name[{$lang}]=") === 0) {
                    $found = true;
                    $targetLineNumber = $lineNumber;
                }
            }

            assert($rawNameLineNumber >= 0);

            if (!$found) {
                array_splice($desktop, $rawNameLineNumber + 1, 0, "Name[{$lang}]={$translation}");
            } else {
                $desktop[$targetLineNumber] = "Name[{$lang}]={$translation}";
            }

            file_put_contents($desktopFile, implode("\n", $desktop));
        }
        if ((string) $context->name === CONTEXT_POLKIT_FILE) {
            $translation = (string) $context->message->translation;
            $polkit = new SimpleXMLElement(file_get_contents($polkitFile));
            $ns = $polkit->getNamespaces(true);
            $ns['xml'] ??= 'http://www.w3.org/XML/1998/namespace';
            $messages = $polkit->action->message;

            $found = false;

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
                $found = true;
                break;
            }

            if (!$found) {
                $newMessage = $polkit->action->addChild('message', $translation);
                $newMessage->addAttribute('xml:lang', $lang);
            }

            file_put_contents($polkitFile, $polkit->asXML());
        }
    }
}
