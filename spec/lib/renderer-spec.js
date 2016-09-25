const path = require('path');
const fs = require('fs');

const renderer = require('../../lib/renderer.coffee');
const util = require('../../lib/util.coffee');
const { configSchema: { configFilePath: { default: defaultPath } } } = require('../../package.json');

const fixturesPath = `..${util.isWin() ? '\\' : '/'}fixture`;

describe('renderer.coffee', function() {
    describe('toDOMFragment', function() {
        const fixturePath = path.resolve(__dirname, fixturesPath, 'jsdoc.js');
        const emptyFixturePath = path.resolve(__dirname, fixturesPath, 'empty-jsdoc.js');
        const emptyHTML = '<h2>No JSDocs to Preview</h2>';
        let fragment;

        beforeEach(() => fragment = null);
        it('should throw an error', function() {
            expect(
                () => renderer.toDOMFragment(path.resolve(__dirname, fixturesPath, 'fake.js'), callback)
            ).toThrow();
        });
        it('should generate an intelligible JSDoc DOM block', function() {
            renderer.toDOMFragment(fixturePath, callback);
            expect(fragment.length).toBeTruthy();
        });
        it('should generate a warning DOM block', function() {
            expect(renderer.toDOMFragment(emptyFixturePath, callback)).toBe(emptyHTML);
        });

        function callback(e, f) {
            if (e) {
                throw e;
            }

            return (fragment = f);
        }
    });
    describe('getConfigFilePath', function() {
        let defaultConfigPath;

        beforeEach(function() {
            defaultConfigPath = path.resolve(process.cwd(), defaultPath);
            atom.config.set('jsdoc-preview.configFilePath', defaultConfigPath);
        });
        xit('should throw an error if a bad path is provided');
        it('should return the default config path', function() {
            expect(renderer._getConfigFilePath()).toBe(defaultConfigPath);
        });
        it('should return a custom config path', function() {
            const customConfigPath = 'foo';

            atom.config.set('jsdoc-preview.configFilePath', customConfigPath);
            expect(renderer._getConfigFilePath()).toEqual(customConfigPath);
        });
    });
    describe('createTempDir', function() {
        it('createTempDir', function() {
            if (util.isWin()) {
                expect(
                    renderer._createTempDir()
                ).toContain('\\Users\\IEUser\\AppData\\Local\\Temp');
            } else {
                expect(renderer._createTempDir()).toContain('/var/folders/');
                expect(renderer._createTempDir()).toContain('/T');
            }
        });
    });
});
