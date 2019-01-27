#!/usr/bin/python

import hashlib

def ecdsa_verify(msg, pk, (r, s), curve=None, hash_fn=hashlib.sha256):
    '''Verifies a signature on a message.
    msg is a string,
    pk is an ecdsa.ECPoint representing the public key
    (r, s) is the signature tuple (use ecdsa.decode_sig to extract from hex)
    '''
    # Boilerplate, leave this alone
    import ecdsa
    if curve is None:
        curve = ecdsa.secp256k1

    # *********************************************************
    # TODO: Remove the raise Exception() and implement your ecdsa_verify function here:
    # Refer to ecdsa.ecdsa_sign() for examples in hashing the message,
    # and doing point multiplication.
    # See https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm#Signature_verification_algorithm
    # for the algorithm.
    #raise Exception('Not implemented!')

    # Get hash of the message as an integer
    e = hash_fn(msg).hexdigest()
    z = int(e, 16)

    # Compute w = s^-1 mod n
    w = ecdsa.modinv(s, curve.n) % curve.n

    # Compute 
    u1 = (z * w) % curve.n

    # Compute 
    u2 = (r * w) % curve.n

    #Compute
    G = curve.G()   # group Generator
    u1G = G.mult(u1)
    uspk = pk.mult(u2)
    C = u1G.add(uspk)

    #Check calculated sig with given sig
    if(r == C.x):
        return True
    else:
        return False

if __name__ == '__main__':
    import ecdsa

    msgs = [
    'Hello, world',
    'The Magic Words are Squeamish Ossifrage.',
    'Attack at Dawn',
    'Attack at Dusk',
    'Create nonces randomly!',
    'Create nonces deterministically!']

    sigs = [
    'e1ca8ca322e963a24e2f2899e21255f275c2889e89adc14e225de6f338d7295aa9ab4ba5ddaa4366c4b32fb2b32371d768431b9c2cd7eee487215370a1196b49',
    'a86f5a5539e9ac49311c610f120e173ce8cb45f9493fe6a27dd81a1a22b08a2ce26a64013af4a894ab6e71df3dc3b775c8805de7c802f2e43791828be31a330c',
    'e1ca8ca322e963a24e2f2899e21255f275c2889e89adc14e225de6f338d7295ae556841b91642ea868014a9616e8ae6a8ae35bacf2e85f6e556d4bda910374f1',
    '64a70a19b87fe1c418964fe1751bbe641ea3d2f1cd70e346c722b59cdac587d857974c4683faa977789a78db471fc0cc7fafd20f31d67097e77b110789593029',
    '5b1a427f8d61345b15c716203c1e15b4370a1c841a92e88d61e021b794a209962f342d6467ae8c29a7fb25619e107381b5b252df90fe8d54bc6ecd2f41d66b83',
    'd580841c6864728bcf664a62c3ed552974c252badbecc53c53fe14e1ee922fb0b5186168ffd3cc798186660d5afadab9e088ac9f3397b64c7437bf2926d871a9']

    pub_key = '0220b6617270f57c3cd2bc3f14f5c7c37390ca790c4e30e65f77d4d9af7e6e14fb'
    pk = ecdsa.decode_pk(pub_key)
    # *******************************************************
    # TODO: Write your code for pairing messages to signatures here

    ordered_sigs=[]

    for msg in msgs:
        for sig in sigs:
            if ecdsa_verify(msg, pk, ecdsa.decode_sig(sig)) == True:
                ordered_sigs.append(sig)
                # print msg,sig

    # *******************************************************
    # TODO: (Graduate students only, optional for undergrad)
    #       Write your code for extracting the private key
    #       and signing your own message here

    def find_k(msg1, (r1,s1), msg2, (r2,s2), curve=ecdsa.secp256k1, hash_fn=hashlib.sha256):
        e1 = hash_fn(msg1).hexdigest()
        z1 = int(e1, 16)

        e2 = hash_fn(msg2).hexdigest()
        z2 = int(e2, 16)

        return (ecdsa.modinv((s1-s2),curve.n) * (z2-z1)) % curve.n

    def get_private_key(msg,(r,s),k,curve=ecdsa.secp256k1, hash_fn=hashlib.sha256):
        # pvt_key = r^-1(s*k-z) mod n
        e = hash_fn(msg).hexdigest()
        z = int(e, 16)
        return (ecdsa.modinv(r, curve.n) * (s*k - z )) % curve.n
    
    k_list=[]

    for i in range(len(msgs)):
        for j in range(i+1,len(msgs)):
            k_list.append(find_k(msgs[i],ecdsa.decode_sig(ordered_sigs[i]),msgs[j],ecdsa.decode_sig(ordered_sigs[j])))


    for k in k_list:
        print k

    for i in range(len(k_list)):
        for j in range(i+1,len(k_list)):
            if(k_list[i] == k_list[j] and k_list[i] != 0):
                print "found",i,j
                get_private_key(msgs[i],ecdsa.decode_sig(ordered_sigs[i]),k_list[i])

    # skey = get_private_key(msgs[0],ecdsa.decode_sig(ordered_sigs[0]),0L)

    # new_sign = ecdsa.ecdsa_sign(msg[3], skey)

    # print 'Signature: ', ecdsa.encode_sig(new_sign)

    # if ecdsa_verify(msgs[3], pk, new_sign) == True:
    #     print 'Signature Verified!'
    # else:
    #     print "Not verified"
