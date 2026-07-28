import assert from 'node:assert/strict'
import { slugify } from './slugify.js'

assert.equal(slugify('Nostalgia'), 'nostalgia')
assert.equal(slugify('Días de Diseño'), 'dias-de-diseno')
assert.equal(slugify('  Espacios   raros  '), 'espacios-raros')
assert.equal(slugify('¿Qué pasa?'), 'que-pasa')
assert.equal(slugify('El futuro / el pasado'), 'el-futuro-el-pasado')
assert.equal(slugify('100% Analógico'), '100-analogico')
assert.equal(slugify('---'), '')
assert.equal(slugify(''), '')
assert.equal(slugify(null), '')

console.log('slugify OK')
