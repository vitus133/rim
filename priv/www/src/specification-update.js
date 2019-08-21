/**
 * @license
 * Copyright (c) 2019 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt
 */

import { PolymerElement, html } from '@polymer/polymer/polymer-element.js';
import '@polymer/iron-ajax/iron-ajax.js';
import '@polymer/paper-fab/paper-fab.js';
import '@polymer/iron-icons/iron-icons.js';
import '@polymer/paper-dialog/paper-dialog.js';
import '@polymer/paper-toolbar/paper-toolbar.js';
import '@polymer/paper-input/paper-input.js';
import '@polymer/paper-button/paper-button.js';
import '@polymer/paper-dropdown-menu/paper-dropdown-menu.js';
import '@polymer/paper-listbox/paper-listbox.js';
import '@polymer/paper-item/paper-item.js'
import '@polymer/paper-checkbox/paper-checkbox.js'
import '@polymer/iron-collapse/iron-collapse.js';
import './style-element.js';

class specUpdateList extends PolymerElement {
	static get template() {
		return html`
			<style include="style-element">
			</style>
		<paper-dialog class="dialog" id="updateSpecModal" modal>
			<paper-toolbar>
				<div slot="top"><h2>Update Specification</h2></div>
			</paper-toolbar>
				<paper-input
						id="addSpecId"
						label="Name"
						value="{{specification.specId}}"
						disabled>
				</paper-input>
				<paper-input
						id="addSpecName"
						label="Name"
						value="{{specification.specName}}"
						required>
				</paper-input>
				<paper-input
						id="addSpecDesc"
						label="Description"
						value="{{specification.specDesc}}">
				</paper-input>
				<paper-input
						id="addSpecType"
						label="Class"
						value="{{specification.specClass}}">
				</paper-input>
				<paper-dropdown-menu
					id="specStatus"
					class="drop"
					label="Status"
					value="{{specification.specStatus}}"
					no-animations="true">
					<paper-listbox
							id="updateStatus"
							slot="dropdown-content">
						<paper-item>In Study</paper-item>
						<paper-item>In Design</paper-item>
						<paper-item>In Test</paper-item>
						<paper-item>Rejected</paper-item>
						<paper-item>Active</paper-item>
						<paper-item>Launched</paper-item>
						<paper-item>Retired</paper-item>
						<paper-item>Obsolete</paper-item>
					</paper-listbox>
				</paper-dropdown-menu>
				<div>
					<span>Characteristics</span>
						<paper-icon-button
							id="collapseChar"
							icon="arrow-drop-down"
							on-click="_collapseChars">
						</paper-icon-button>
				</div>
				<iron-collapse id="charSpecCollapse">
					<template is="dom-repeat" items="[[specification.specChars]]">
						<div>
						<hr>
						<paper-input
							id="charName"
							label="Name"
							value="{{item.name}}">
						</paper-input>
						<paper-input
							id="charDesc"
							label="Description"
							value="{{item.description}}">
						</paper-input>
						<paper-input
							id="charValueType"
							label="ValueType"
							value="{{item.valueType}}">
						</paper-input>
						</div>
					</template>
				</iron-collapse>
				<div class="buttons">
					<paper-button
							raised
							class="update-button"
							on-tap="_updateSpec">
						Update
					</paper-button>
					<paper-button
							class="cancel-button"
							dialog-dismiss
							on-tap="cancelSpec">
						Cancel
					</paper-button>
					<paper-button
							toggles
							raised
							class="delete-button"
							on-tap="_deleteSpec">
						Delete
					</paper-button>
				</div>
		</paper-dialog>
		<iron-ajax
			id="deleteSpecificationAjax"
			on_response="_deleteSpecificationResponse"
			on-error="_deleteSpecificationError">
		</iron-ajax>
		<iron-ajax
			id="specUpdateAjax"
			content-type="application/merge-patch+json"
			on-loading-changed="_onLoadingChanged"
			on-response="_addSpecResponse"
			on-error="_addSpecError">
		</iron-ajax>
		`;
	}

	static get properties() {
		return {
			specification: {
				type: Object,
			}
		}
	}

	ready() {
		super.ready()
	}

	_deleteSpec() {
		var ajax1 = this.$.deleteSpecificationAjax;
		ajax1.method = "DELETE";
		ajax1.url = "/resourceCatalogManagement/v3/resourceSpecification/" + this.$.addSpecId.value;
		ajax1.generateRequest();
		var deleteObj =  document.body.querySelector('inventory-management').shadowRoot.querySelector('specification-update').shadowRoot.getElementById('updateSpecModal');
		deleteObj.close();
	}

	_updateSpec() {
		var ajax = this.$.specUpdateAjax;
		ajax.method = "PATCH";
		ajax.url = "/resourceCatalogManagement/v3/resourceSpecification/" + this.$.addSpecId.value;
		var spec = new Object();
		if(this.$.addSpecName.value) {
			spec.name = this.$.addSpecName.value;
		}
		if(this.$.addSpecDesc.value) {
			spec.description = this.$.addSpecDesc.value;
		}
		if(this.$.addSpecType.value) {
			spec["@type"] = this.$.addSpecType.value;
		}
		if(this.$.specStatus.value) {
			spec.lifecycleStatus = this.$.specStatus.value;
		}
		ajax.body = JSON.stringify(spec);
		ajax.generateRequest();
	}

	_collapseChars(event) {
		var collapseModal = document.querySelector('inventory-management').shadowRoot.getElementById('updateSpec').shadowRoot.getElementById('charSpecCollapse');
		if(collapseModal.opened == false) {
			collapseModal.show();
		} else {
			collapseModal.hide();
		}
	}
}

window.customElements.define('specification-update', specUpdateList);
