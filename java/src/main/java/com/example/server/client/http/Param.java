package com.example.server.client.http;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.Getter;

@Getter
public class Param {

    String name;
    String value;

    public static Map<String, String> paramList2Map(List<Param> params) {
        return params == null ? new HashMap<>() : params.stream().collect(Collectors.toMap(Param::getName, Param::getValue));
    }

    public Param(String name, String value) {
        this.name = name;
        this.value = value;
    }

    public String toString() {
        return "Param(name=" + name + ", value=" + value + ")";
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }

        if (!(o instanceof Param other)) {
            return false;
        }

        if (!other.canEqual(this)) {
            return false;
        }

        Object this$name = name;
        Object other$name = other.getName();
        if (this$name == null) {
            return other$name == null;
        }

        Object this$value = value;
        Object other$value = other.getValue();
        if (this$value == null) {
            return other$value == null;
        }

        return true;
    }

    boolean canEqual(Object other) {
        return other instanceof Param;
    }

    public int hashCode() {
        int prime1 = 59;
        int prime2 = 43;
        int result = 1;
        Object $name = name;
        result = result * prime1 + ($name == null ? prime2 : $name.hashCode());
        Object $value = value;
        result = result * prime1 + ($value == null ? prime2 : $value.hashCode());
        return result;
    }

}
