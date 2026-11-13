import test from 'node:test';
import assert from 'node:assert/strict';
import {appendDictation,dictationError,recognitionConstructor} from '../src/lib/dictation';
test('dictation appends to existing manual text without replacing it',()=>{assert.equal(appendDictation('Texto manual.','  Nuevo hallazgo. '),'Texto manual. Nuevo hallazgo.');assert.equal(appendDictation('Texto manual.\n','Nuevo hallazgo.'),'Texto manual.\nNuevo hallazgo.');assert.equal(appendDictation('Texto manual.','   '),'Texto manual.');});
test('server rendering and microphone failures do not require speech support',()=>{assert.equal(recognitionConstructor(),undefined);for(const code of ['not-allowed','audio-capture','no-speech','network','unknown'])assert.match(dictationError(code),/escrib|texto/);});
