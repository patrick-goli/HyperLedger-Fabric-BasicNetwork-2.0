
package org.hyperledger.fabric.samples.fabcar;

import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import com.owlike.genson.annotation.JsonProperty;

@DataType()
public final class Key {
    @Property()
    private String key;

    public String getKey() {
        return key;
    }

    public Key(@JsonProperty("key") final String key) {
        this.key = key;
    }
}
